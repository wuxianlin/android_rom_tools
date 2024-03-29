#!/usr/bin/env bash
#
# Copyright 2020 wuxianlin(wuxianlinwxl@gmail)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

MYDIR=`dirname $(readlink -f $0)`

ROMZIP=$1
OUT=$2


if [ -z "$OUT" ]
then
	OUT=./out
fi

mkdir -p $OUT
rm -rf $OUT/*

unzip -q -o $1 -d $OUT/rom
rm $1
if [ -f $OUT/rom/payload.bin ];then
    python3 $MYDIR/payload_dumper/payload_dumper.py $OUT/rom/payload.bin --out $OUT/rom
    rm $OUT/rom/payload.bin
    #$MYDIR/tools/deimg.sh $OUT/rom
elif [ -f $OUT/rom/UPDATE.APP ];then
    for app in `find $OUT/rom -name *.APP`;do
        python $MYDIR/splituapp/splituapp -f $app -s -o $OUT/rom
        rm $app
    done
else
    for datsplit in `find $OUT/rom -name  *.new.dat.*|sort --version-sort`;do
	path=$(dirname $datsplit)
	datname=$(basename $datsplit)
	partname=${datname%%.*}
        if [ -f $path/$partname.new.dat ];then
	    cat $datsplit >> $path/$partname.new.dat
	    rm $datsplit
        fi
    done
    $MYDIR/tools/dedat.sh $OUT/rom
fi
#if [ -d $OUT/rom/vendor/euclid ];then
#    $MYDIR/tools/deimg.sh $OUT/rom/vendor/euclid
#fi
$MYDIR/tools/deimg.sh $OUT/rom

if [ -d $OUT/rom/system/system ];then
	mv $OUT/rom/system $OUT/rom/system_root
	mv $OUT/rom/system_root/system $OUT/rom/system
fi

sdk=0
for prop in `find $OUT/rom -name build*.prop`;do
	sdkversion=`cat $prop|grep ro.build.version.sdk`
	if [ $sdkversion ];then
		sdk=${sdkversion#*=}
	fi
done
echo found sdk version $sdk
if [ $sdk -ge 26 ]; then
	$MYDIR/tools/devdex.sh $OUT/rom $OUT/rom-deodexed
elif [ $sdk -ge 23 ];then
	$MYDIR/tools/deoat.sh $OUT/rom $OUT/rom-deodexed
elif [ $sdk -ge 21 ];then
	$MYDIR/tools/deoat-oat2dex.sh $OUT/rom $OUT/rom-deodexed
else
	$MYDIR/tools/deodex.sh $sdk $OUT/rom $OUT/rom-deodexed
fi
