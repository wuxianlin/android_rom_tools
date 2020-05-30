#!/usr/bin/env bash

GITHUB_TOKEN=$1

git clone https://github.com/anestisb/vdexExtractor

cd vdexExtractor
./make.sh
. tools/deodex/constants.sh

for ((i=28;;i++));do
	echo $i
	deps_zip="bin/api-$i/deps.zip"
	download_url="L_DEPS_URL_API_$i"
        deps_latest_sig="L_DEPS_API_$i""_SIG"
	if [ ! ${!download_url} -o ! ${!deps_latest_sig} ];then
		((max_api_level=$i-1))
		echo $max_api_level > bin/max_api_level
		echo not found api level $i,the max api level supported is $max_api_level
		break
	fi
	mkdir bin/api-$i
	axel -n 10 -o $deps_zip ${!download_url}
	if [[ "$(shasum -a256 $deps_zip | cut -d ' ' -f1)" == "${!deps_latest_sig}" ]];then
		unzip -q -o $deps_zip -d bin/api-$i
	fi
done

cd ..

if [ $GITHUB_TOKEN ];then
	LATEST_JADX_JSON=$(curl --fail --retry 3 -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/skylot/jadx/releases/latest)
else
	LATEST_JADX_JSON=$(curl --fail --retry 3 https://api.github.com/repos/skylot/jadx/releases/latest)
fi
JADX_ASSET_URL=$(echo "$LATEST_JADX_JSON" | jq -r '.assets[].browser_download_url | select(contains("gui")|not)')
echo $JADX_ASSET_URL
curl --silent --show-error --location --fail --retry 3 --output jadx.zip $JADX_ASSET_URL
unzip -q -o jadx.zip -d jadx

make -C oatdumpdexloc

git clone https://github.com/xpirt/sdat2img

mkdir tools

if [ $GITHUB_TOKEN ];then
	SMALI_TAGS=$(curl --fail --retry 3 -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/JesusFreke/smali/tags)
else
	SMALI_TAGS=$(curl --fail --retry 3 https://api.github.com/repos/JesusFreke/smali/tags)
fi
for tag in `echo "$SMALI_TAGS" |jq -r ".[].name"`;do
	version=${tag/v/}
	baksmali="baksmali-$version.jar"
	smali="smali-$version.jar"
	curl --silent --show-error --location --fail --retry 3 --output tools/$baksmali https://bitbucket.org/JesusFreke/smali/downloads/$baksmali
	curl --silent --show-error --location --fail --retry 3 --output tools/$smali https://bitbucket.org/JesusFreke/smali/downloads/$smali
	if [ -f tools/$baksmali -a -f tools/$smali ];then
		break
	fi
done

if [ $GITHUB_TOKEN ];then
	LATEST_APKTOOL_JSON=$(curl --fail --retry 3 -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/iBotPeaches/Apktool/releases/latest)
else
	LATEST_APKTOOL_JSON=$(curl --fail --retry 3 https://api.github.com/repos/iBotPeaches/Apktool/releases/latest)
fi
APKTOOL_ASSET_URL=$(echo "$LATEST_APKTOOL_JSON" | jq -r '.assets[].browser_download_url')
APKTOOL_NAME=$(echo "$LATEST_APKTOOL_JSON" | jq -r '.assets[].name')
echo $APKTOOL_ASSET_URL
echo $APKTOOL_NAME
curl --silent --show-error --location --fail --retry 3 --output tools/$APKTOOL_NAME $APKTOOL_ASSET_URL

#LATEST_OAT2DEX_JSON=$(curl --fail --retry 3 -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/testwhat/SmaliEx/releases/latest)
#OAT2DEX_ASSET_URL=$(echo "$LATEST_OAT2DEX_JSON" | jq -r '.assets[].browser_download_url | select(contains("oat2dex.jar"))')
OAT2DEX_ASSET_URL="https://github.com/testwhat/SmaliEx/releases/download/snapshot/oat2dex.jar"
echo $OAT2DEX_ASSET_URL
curl --silent --show-error --location --fail --retry 3 --output tools/oat2dex.jar $OAT2DEX_ASSET_URL

