#!/usr/bin/env bash

MYDIR=`dirname $0`
ROM=$1

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
	sudo mount -o ro,loop $img $outdir || sudo mount -t erofs -o ro,loop $img $outdir
        if [ $? -ne 0 ]; then
            rm -rf $outdir
	    echo "deimg done, not support"
        else
	    sudo cp -r $outdir $path/$partname
	    sudo chown -R $name:$name $path/$partname
	    sudo umount $outdir
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
