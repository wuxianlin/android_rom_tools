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
tools/dedat.sh $OUT/rom

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
	tools/devdex.sh $OUT/rom $OUT/rom-deodexed
elif [ $sdk -ge 23 ];then
	tools/deoat.sh $OUT/rom $OUT/rom-deodexed
elif [ $sdk -ge 21 ];then
	tools/deoat-oat2dex.sh $OUT/rom $OUT/rom-deodexed
else
	tools/deodex.sh $sdk $OUT/rom $OUT/rom-deodexed
fi
