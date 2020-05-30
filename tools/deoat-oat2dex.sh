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

OAT2DEX=tools/oat2dex.jar
if [ ! -r "$OAT2DEX" ]
then
    echo "can't find $OAT2DEX"
    exit 1
fi

mkdir $OUT
rm -rf $OUT/*

if [ -d $ROM/system/framework ];then
	mkdir -p $OUT/system/framework
	java -jar $OAT2DEX devfw $ROM/system/framework

	cp boot-jar-with-dex/*.jar $OUT/system/framework/
	cp framework-jar-with-dex/*.jar $OUT/system/framework/

	rm -rf boot-jar-original boot-jar-with-dex framework-jar-original framework-jar-with-dex  framework-odex
fi

for odex in `find $ROM -name *.odex|grep -v $ROM/system/framework`; do
	echo "---- start deodex $odex ----"
	apk=${odex##*/}
	apk=${apk/%odex/apk}
	folder=${odex%/*}
	folder=${folder%/*}
	out=${folder/$ROM/$OUT}
	mkdir -p $out
	cp $folder/$apk $out
	if unzip -v $out/$apk | grep " classes.dex" >/dev/null; then
		echo "---- $apk is already deodexed ----"
		echo " "
		continue
	fi
	java -jar $OAT2DEX -o $OUT $odex ./boot-raw
	output=$OUT/${apk/%.apk/}
	for dex in $output*; do
		if [ $dex = $output.dex ];then
			apkdex=classes.dex
		else
			apkdex=${dex#$output-}
		fi
		echo "copying $dex to $apkdex"
		cp $dex $apkdex
		jar uf $out/$apk $apkdex
		rm $dex $apkdex
	done
	echo "$folder $apk $out $output"
	echo "---- deodex $odex done ----"
	echo " "
done

rm -rf boot-raw

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
