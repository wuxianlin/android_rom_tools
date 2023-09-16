#!/usr/bin/env bash
#
# Copyright (C) 2017 wuxianlin(wuxianlinwxl@gmail.com)
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

APILEVEL=$1
ROM=$2
OUT=$3

if [ -z "$APILEVEL" ]
then
        APILEVEL=19
fi

if [ -z "$ROM" ]
then
	ROM=.
fi

if [ -z "$OUT" ]
then
	OUT=./out
fi

mkdir -p $OUT
rm -rf $OUT/*

smali=$(find $MYDIR -name "*smali*" -not -name "*baksmali*"|sort -r --version-sort|grep -m1 jar)
baksmali=$(find $MYDIR -name "*baksmali*.jar"|sort -r --version-sort|grep -m1 jar)
if [ "$smali" = "" ] || [ "$baksmali" = "" ]; then
     echo "baksmali or smali not found"
     exit 1
fi

for oat in `find $ROM -name *.odex`; do
     echo "---- start deodex $oat ----"
     oatfolder=${oat%/*}
     oatname=$(basename $oat)
     apkpath=$(find $oatfolder -name ${oatname%.*}.jar -o -name ${oatname%.*}.apk -not -name *.odex)
     if [ $apkpath ];then
        outfolder=${oatfolder/$ROM/$OUT}
	outpath=${apkpath/$ROM/$OUT}
        mkdir -p $outfolder
        cp $apkpath $outfolder
	if unzip -v $outpath | grep " classes.dex" >/dev/null; then
		echo "---- $outpath is already deodexed ----"
		echo " "
		continue
	fi
        java -jar $baksmali deodex -a $APILEVEL -o $OUT/dexout -d $ROM/system/framework $oat
        java -jar $smali assemble -a $APILEVEL $OUT/dexout -o $OUT/classes.dex
        zip -gjq $outpath $OUT/classes.dex
        rm -rf $OUT/dexout $OUT/classes.dex
     fi
     echo "---- deodex $oat done ----"
     echo " "
done

for apk in `find $ROM -name *.apk -o -name *.jar`; do
	apkfolder="$(dirname $apk)"
	folder=${apkfolder#$ROM*}
	foldermaybe=${folder/system/}
	apkname="$(basename $apk)"
	if [ ! -f $OUT/$folder/$apkname -a  ! -f $OUT/$foldermaybe/$apkname ];then
		mkdir -p $OUT/$folder
		cp $apk $OUT/$folder
	fi
done
