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

ROM=$1
OUT=$2

if [ -z "$ROM" ]
then
	ROM=.
fi

if [ -z "$OUT" ]
then
	OUT=./out
fi

mkdir $OUT
rm -rf $OUT/*

smali=$(find $MYDIR -name *smali* -not -name *baksmali*)
baksmali=$(find $MYDIR -name *baksmali*)
if [ "$smali" = "" ] || [ "$baksmali" = "" ]; then
     echo "baksmali or smali not found"
     exit 1
fi

for oat in `find $ROM -name *.oat -o -name *.odex`; do
     echo "---- start deodex $oat ----"
     oatfolder="$(dirname $oat)"
     oatname="$(basename $oat)"
     arch=${oatfolder##*/}
     #echo $arch
     if [ -f $oatfolder"64/"$oatname ] || [ -f $oatfolder"_64/"$oatname ]; then
          echo "---- $oatfolder"64/"$oatname exists ----"
          echo "---- deodex $oat stop ----"
          echo " "
          continue
     fi
     dexlist=$(java -jar $baksmali list dex $oat)
     #echo $dexlist
     for dex in $dexlist ; do
          #echo $dex
          dexname=${dex#*:}
          jar=${dex%:*}
          jarfolder=${jar%/*}
          if [ "$dexname" = "$dex" ]; then
               dexname="classes.dex"
               mkdir -p $OUT/$jarfolder
               cp $ROM/$jar $OUT/$jar
               if unzip -v $OUT/$jar | grep " classes.dex" >/dev/null; then
                       continue # target apk|jar is already odexed, return
               fi
          fi
          echo $jar $dexname
          java -jar $baksmali deodex -o $OUT/dexout -b $ROM/system/framework/$arch/boot.oat -d $ROM/system/framework/$arch $oat$dex
          java -jar $smali assemble $OUT/dexout -o $OUT/$dexname
          zip -gjq $OUT$jar $OUT/$dexname
          rm -rf $OUT/dexout $OUT/$dexname
     done
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
