#!/usr/bin/env bash
#
# Copyright 2017 wuxianlin(wuxianlinwxl@gmail)
# Copyright 2015 Coron
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

SDAT2IMG=$MYDIR/../sdat2img/sdat2img.py
if [ ! -r "$SDAT2IMG" ]
then
    echo "can't find $SDAT2IMG"
    exit 1
fi

for list in `find $ROM -name *.transfer.list`;do
	path=$(dirname $list)
	listname=$(basename $list)
	partname=${listname%%.*}
	echo "start dedat $path/$partname"
	[ -e $path/$partname.new.dat.br ] && brotli --decompress $path/$partname.new.dat.br --output=$path/$partname.new.dat && rm $path/$partname.new.dat.br
	[ -e $path/$partname.new.dat ] && $SDAT2IMG $list $path/$partname.new.dat $path/$partname.img && rm $list $path/$partname.new.dat $path/$partname.patch.dat
	[ ! -e $path/$partname.img ] && continue
	echo "dedat done, output:$path/$partname.img"
done
