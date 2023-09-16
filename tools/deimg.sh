#!/usr/bin/env bash

MYDIR=`dirname $(readlink -f $0)`
ROM=$1

check_simg() {
        TOOL=$1
        IMG=$2
        imgfiletype=`file $IMG`
        if [[ "$imgfiletype" == *"Android sparse image"* ]];then
            echo found android sparse image
            $TOOL $IMG ${IMG}.raw
            if [ $? -ne 0 ]; then
                echo simg2img faild
                rm $IMG.raw
            else
                echo simg2img success
                rm $IMG
                mv ${IMG}.raw $IMG
            fi
        fi
}

unpack_img() {
        MYDIR=$1
        img=$2
        OUTDIR=$3
	name=`whoami`
	tmpdir=`mktemp -d /tmp/dedat.mount.XXXXX`
        check_simg $MYDIR/../otatools/bin/simg2img $img
	USESUDO=0
	$MYDIR/../erofs-utils/fuse/erofsfuse $img $tmpdir || $MYDIR/../e2fsprogs/misc/fuse2fs -o fakeroot,ro $img $tmpdir
	if [ $? -ne 0 ]; then
	    USESUDO=1
	    sudo mount -o ro,loop $img $tmpdir
	fi
        if [ $? -ne 0 ]; then
            rm -rf $tmpdir
	    echo "deimg done, not support"
        else
	    if [ $USESUDO -eq 1 ];then
	        if [ -d $OUTDIR ];then
	            sudo cp -r $tmpdir/* $OUTDIR/
	        else
	            sudo cp -r $tmpdir $OUTDIR
	        fi
	        sudo chown -R $name:$name $OUTDIR
	        sudo umount $tmpdir
	    else
	        if [ -d $OUTDIR ];then
	            cp -r $tmpdir/* $OUTDIR/
	        else
	            cp -r $tmpdir $OUTDIR
	        fi
	        fusermount -u $tmpdir
	    fi
	    rm -rf $tmpdir
	    echo "deimg done, output:$OUTDIR"
            rm $img
        fi
}

#unpack boot image
for img in `find $ROM -name *boot.img -o -name *recovery.img -o -name *ramdis.img -o -name *ramdisk.img`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	echo found $imgname image
	$MYDIR/../AIK-Linux/unpackimg.sh --nosudo $img
	if [ $? -eq 0 ]; then
	    mv $MYDIR/../AIK-Linux/ramdisk $path/$partname
	    mv $MYDIR/../AIK-Linux/split_img $path/${partname}_img
	    rm $img
	fi
	$MYDIR/../AIK-Linux/cleanup.sh
done

#moto and qcom rom
for img in `find $ROM -name *_sparsechunk.0`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%_*}
	$MYDIR/../otatools/bin/simg2img $path/${partname}_sparsechunk.* $path/${partname}
	rm $path/${partname}_sparsechunk.*
done

#huawei rom
for img in `find $ROM -name super_*.img|sort --version-sort`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	echo found super image $img
	check_simg $MYDIR/../otatools/bin/simg2img $img
	mkdir $path/$partname
	$MYDIR/../otatools/bin/lpunpack $img $path/$partname
	if [ $? -ne 0 ]; then
		echo failed to lpunpack
		echo try huawei scheme
		if [ -f $path/super.img ];then
			check_simg $MYDIR/../otatools/bin/simg2img $path/super.img
			dd if=$path/super.img of=$img bs=1048576 count=1 conv=notrunc
		fi
	else
 		rm -rf $path/$partname
	fi
done

#lpunpack super image
for img in `find $ROM -name "super*.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	echo found super image $img
	check_simg $MYDIR/../otatools/bin/simg2img $img
	mkdir $path/$partname
	$MYDIR/../otatools/bin/lpunpack $img $path/$partname
	for childimg in `find $path/$partname -name "*.img"`;do
	    childimgname=$(basename $childimg)
	    if [ "$(tr -d '\0' < $childimg | wc -c)" -eq 0 ]; then
	        echo "All zeroes."
	        rm $childimg
	    elif [ ! -f $path/$childimgname ]; then
	        mv $childimg $path/$childimgname
	    fi 
	done
	rm $img
done

for img in `find $ROM -name "*_a.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%_a.img}
	if [ ! -f $path/${partname}.img ];then
	    mv $img $path/${partname}.img
	fi
done

for img in `find $ROM -name "*_b.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%_b.img}
	if [ ! -f $path/${partname}.img ];then
	    mv $img $path/${partname}.img
	elif [ ! -f $path/${partname}_other.img ];then
	    mv $img $path/${partname}_other.img
	fi
done

#unpack common image
for img in `find $ROM -name "*.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	check_simg $MYDIR/../otatools/bin/simg2img $img
	unpack_img $MYDIR $img $path/$partname
done

#unpack apex
for apex in `find $ROM -name *.apex`;do
    echo $apex
    outapex=${apex/.apex/}
    mkdir -p $outapex
    unzip -o $apex -d $outapex
    rm $apex
    if [ -f $outapex/apex_payload.img ];then
        echo start unpack $outapex/apex_payload.img
        img=$outapex/apex_payload.img
	unpack_img $MYDIR $img $outapex
    fi
done
