#!/usr/bin/env bash
#
# Copyright 2017 wuxianlin(wuxianlinwxl@gmail)
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
VDEX_EXTRACTOR_BIN=$MYDIR/../vdexExtractor/bin/vdexExtractor
cdexConvBin=$MYDIR/../vdexExtractor/bin/api-28/bin/compact_dex_converter
maxapilevel=`cat $MYDIR/../vdexExtractor/bin/max_api_level`

if [ ! $maxapilevel ];then
	maxapilevel=28
fi

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

for vdex in `find $ROM -name *.vdex -type f`; do
	echo "---- start devdex $vdex ----"
	oat=${vdex/vdex/oat}
	odex=${vdex/vdex/odex}
	vdexfolder="$(dirname $vdex)"
	vdexname="$(basename $vdex)"
	#arch=${vdexfolder##*/}
	if [ -f $vdexfolder"64/"$vdexname ] || [ -f $vdexfolder"_64/"$vdexname ]; then
		echo "---- $vdexfolder"64/"$vdexname exists ----"
		echo "---- devdex $vdex stop ----"
		echo " "
		continue
	fi
	if [ -f $oat ]; then
		#echo $oat
		dexlist="$($MYDIR/../oatdumpdexloc/oatdumpdexloc -i $oat)"
	elif [ -f $odex ]; then
		#echo $odex
		dexlist="$($MYDIR/../oatdumpdexloc/oatdumpdexloc -i $odex)"
	else
		for oat in `find $vdexfolder -name ${vdexname/vdex/oat} -o -name ${vdexname/vdex/odex}`;do
			oatfolder="$(dirname $oat)"
			oatname="$(basename $oat)"
			if [ -f $oatfolder"64/"$oatname ] || [ -f $oatfolder"_64/"$oatname ]; then
				echo "---- $oatfolder"64/"$oatname exists ----"
				continue
			fi
			dexlist="$($MYDIR/../oatdumpdexloc/oatdumpdexloc -i $oat)"
		done
		if [ ! "$dexlist" ];then
			echo "error while devdexing $vdex"
			continue
		fi
	fi
	apiLevel=$($VDEX_EXTRACTOR_BIN --get-api -i "$vdex" || echo "API-0")
	apiLevel=${apiLevel//API-/}
	cdexConvBinTmp=$MYDIR/../vdexExtractor/bin/api-$apiLevel/bin/compact_dex_converter
	if [ -f $cdexConvBinTmp ];then
		cdexConvBin=$cdexConvBinTmp
        elif [ $apiLevel -gt $maxapilevel ];then
		cdexConvBin=$MYDIR/../vdexExtractor/bin/api-$maxapilevel/bin/compact_dex_converter
	fi
	#echo $cdexConvBin
	for dex in $dexlist; do
		#if echo $dex | grep ":classes[0-9]\{0,\}.dex$">/dev/null; then
		#if test "`echo $dex | grep ":classes[0-9]\{0,\}.dex$"`"; then
		if [[ $dex == *:*dex ]]; then
			jar=${dex%:*}
			dex=${dex#*:}
		#elif echo $dex | grep "!classes[0-9]\{0,\}.dex$">/dev/null; then
		#elif test "`echo $dex | grep "!classes[0-9]\{0,\}.dex$"`"; then
		elif [[ $dex == *!*dex ]]; then
			jar=${dex%!*}
			dex=${dex#*!}
		else
			jar=${dex}
			dex=classes.dex
			jarfolder="$(dirname $jar)"
			mkdir -p $OUT/$jarfolder
			jarname=${jar#*/}
			jarname=${jarname#*/}
			jarname2=${jarname#*/}
			vdexpath=${vdex#$ROM*}
			vdexpath=${vdexpath#*/}
			vdexpath=${vdexpath%%/*}
			if [ -f $ROM/$vdexpath/$jarname ]; then
				jar=/$vdexpath/$jarname
				jarfolder="$(dirname $jar)"
				mkdir -p $OUT/$jarfolder
				cp $ROM/$vdexpath/$jarname $OUT/$jarfolder
			elif [ -f $ROM/$vdexpath/$jarname2 ]; then
				jar=/$vdexpath/$jarname2
				jarfolder="$(dirname $jar)"
				mkdir -p $OUT/$jarfolder
				cp $ROM/$vdexpath/$jarname2 $OUT/$jarfolder
			elif [ -f $ROM/$jar ]; then
				cp $ROM/$jar $OUT/$jarfolder
			elif [ -f $ROM/system/$jar ]; then
				cp $ROM/system/$jar $OUT/$jarfolder
			else
				echo "---- $jar not found ----"
				break
			fi
			if unzip -v $OUT/$jar | grep " classes.dex" >/dev/null; then
				echo "---- $jar is already devdexed ----"
				break
			fi
			$VDEX_EXTRACTOR_BIN -i $vdex --ignore-crc-error -o $OUT
		fi
		echo $jar $dex
		cdex=${dex/dex/cdex}
		if [ -f $OUT/${vdexname/.vdex/}*$cdex ];then
			$cdexConvBin $OUT/${vdexname/.vdex/}*$cdex
			rm $OUT/${vdexname/.vdex/}*$cdex
			mv $OUT/${vdexname/.vdex/}*$cdex.new $OUT/$dex
		else
			mv $OUT/${vdexname/.vdex/}*$dex $OUT/$dex
		fi
		zip -gjq $OUT/$jar $OUT/$dex
		rm $OUT/$dex
	done
	echo "---- devdex $vdex done ----"
	echo " "
done

find $OUT -name *dex
for apk in `find $ROM -name *.apk -o -name *.jar -o -name *.hap`; do
	apkfolder="$(dirname $apk)"
	folder=${apkfolder#$ROM*}
	foldermaybe=${folder/system/}
	apkname="$(basename $apk)"
	if [ ! -f $OUT/$folder/$apkname -a  ! -f $OUT/$foldermaybe/$apkname ];then
		mkdir -p $OUT/$folder
		cp $apk $OUT/$folder
		echo copied $OUT/$folder/$apkname
	fi
done

