#!/bin/bash

MYDIR=`dirname $(readlink -f $0)`

ROM=$1
OUT=$2
apktool=$(find $MYDIR -name "apktool*.jar"|sort -r --version-sort|grep -m1 jar)

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

for resapk in `find $ROM -name *-res.apk -o -name miui.apk -o -name miuisystem.apk -o -name miuisdk.apk`;do
	java -jar $apktool if $resapk
done

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
	java -jar $apktool d -f $apk -o $OUT/$outfolder
	#if unzip -v $apk | grep " classes.dex" >/dev/null; then
	#	echo "---- $apk has dex file ----"
	#fi
	echo "---- decompile $apk done ----"
	echo " "
done
