Android decompile tools
==============================================

`sudo apt-get install axel brotli fuse`
`python3 -m pip install -r requirements.txt`

## Usage

download and build tools use `./setup.sh [GITHUB_TOKEN]` 

unpack and deodex rom zip use `./rom.sh rom.zip out`

apktool decompile apk/jar use  `./tools/apktool.sh out/rom-deodexed out/rom-decompiled-apktool`

jadx decompile apk/jar use  `./tools/jadx.sh out/rom-deodexed out/rom-decompiled-jadx`


