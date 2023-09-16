#!/usr/bin/env bash

MYDIR=`dirname $(readlink -f $0)`
ROM=$1

for img in `find $ROM -name *boot.img -o -name *recovery.img`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	echo found $imgname image
	$MYDIR/../AIK-Linux/unpackimg.sh --nosudo $img
	mv $MYDIR/../AIK-Linux/ramdisk $path/$partname
	mv $MYDIR/../AIK-Linux/split_img $path/${partname}_img
	$MYDIR/../AIK-Linux/cleanup.sh
done

for img in `find $ROM -name "super.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	echo found super image
	imgfiletype=`file $img`
	if [[ "$imgfiletype" == *"Android sparse image"* ]];then
	    echo found android sparse image
	    $MYDIR/../otatools/bin/simg2img $img $path/${partname}_ext4.img
	    rm $img
	    mv $path/${partname}_ext4.img $img
	fi
	$MYDIR/../otatools/bin/lpunpack $img $path
	rm $img
done

for img in `find $ROM -name "*.img" -not -name "super.img" -not -name "super_ext4.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	imgfiletype=`file $img`
	name=`whoami`
	outdir=`mktemp -d /tmp/dedat.mount.XXXXX`
	if [[ "$imgfiletype" == *"Android sparse image"* ]];then
	    echo found android sparse image
	    $MYDIR/../otatools/bin/simg2img $img $path/${partname}_ext4.img
	    rm $img
	    mv $path/${partname}_ext4.img $img
	fi
	USESUDO=0
	$MYDIR/../erofs-utils/fuse/erofsfuse $path/$partname.img $outdir
	if [ $? -ne 0 ]; then
	    USESUDO=1
	    sudo mount -o ro,loop $img $outdir
	fi
        if [ $? -ne 0 ]; then
            rm -rf $outdir
	    echo "deimg done, not support"
        else
	    if [ $USESUDO -eq 1 ];then
	        sudo cp -r $outdir $path/$partname
	        sudo chown -R $name:$name $path/$partname
	        sudo umount $outdir
	    else
	        cp -r $outdir $path/$partname
	        fusermount -u $outdir
	    fi
	    rm -rf $outdir
	    echo "deimg done, output:$path/$partname"
            rm $img
        fi
done

for apex in `find $ROM -name *.apex`;do
    echo $apex
    outapex=${apex/.apex/}
    mkdir -p $outapex
    unzip -o $apex -d $outapex
    rm $apex
    if [ -f $outapex/apex_payload.img ];then
        echo start unpack $outapex/apex_payload.img
        img=$outapex/apex_payload.img
	name=`whoami`
	outdir=`mktemp -d /tmp/dedat.mount.XXXXX`
	sudo mount -o ro,loop $img $outdir
        if [ $? -ne 0 ]; then
            rm -rf $outdir
	    echo "deimg done, not support"
        else
	    sudo cp -r $outdir/* $outapex
	    sudo chown -R $name:$name $outapex
	    sudo umount $outdir
	    rm -rf $outdir
	    echo "deimg done, output:$outapex"
            rm $img
        fi
    fi
done
