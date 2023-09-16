#!/bin/bash

MYDIR=`dirname $(readlink -f $0)`

ROM=$1
OUT=$2
JADX_BIN=$MYDIR/../jadx/bin/jadx


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

for apk in `find $ROM -name *.apk -o -name *.jar -o -name *.hap`; do
	echo "---- start decompile $apk ----"
	apkfolder="$(dirname $apk)"
	filenum=`find $apkfolder -name *.apk -o -name *.jar -o -name *.hap | wc -l`
	folder=${apkfolder#$ROM*}
	apknametmp="$(basename $apk)"
	apkname=${apknametmp%.*}
	if [ "${apkfolder##*/}" != "$apkname" ] || [ $filenum -gt 1 ];then
		outfolder=$folder/$apkname
	else
		outfolder=$folder
	fi
	mkdir -p $OUT/$outfolder
	$JADX_BIN $apk --show-bad-code -d $OUT/$outfolder
	#if unzip -v $apk | grep " classes.dex" >/dev/null; then
	#	echo "---- $apk has dex file ----"
	#fi
	echo "---- decompile $apk done ----"
	echo " "
done
