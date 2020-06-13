
ROM=$1

for img in `find $ROM -name "*.img"`;do
	imgname=$(basename $img)
	path=$(dirname $img)
	partname=${imgname%.*}
	name=`whoami`
	outdir=`mktemp -d /tmp/dedat.mount.XXXXX`
	sudo mount -o ro,loop $img $outdir
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
