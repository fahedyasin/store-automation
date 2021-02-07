#!/bin/bash
set -e

spushd() {
     pushd "$1" 2>&1> /dev/null
}

spopd() {
     popd 2>&1> /dev/null
}

info() {
     local green="\033[1;32m"
     local normal="\033[0m"
     echo -e "[${green}INFO${normal}] $1"
}

cmdcheck() {
    command -v $1>/dev/null 2>&1 || { error >&2 "Please install command $1 first."; exit 1; }   
}

error() {
     local red="\033[1;31m"
     local normal="\033[0m"
     echo -e "[${red}ERROR${normal}] $1"
}

warn() {
     local yellow="\033[1;33m"
     local normal="\033[0m"
     echo -e "[${yellow}WARNING${normal}] $1"
}

yesno() {
    while true;do
    read -p "$1 (y/n)" yn
    case $yn in
        [Yy]) $2;break;;
        [Nn]) exit;;
        *) echo 'please enter y or n.'
    esac
done
}

curdir() {
    if [ ${0:0:1} = '/' ] || [ ${0:0:1} = '~' ]; then
        echo "$(dirname $0)"
    elif [ -L $0 ];then
        name=`readlink $0`
        echo $(dirname $name)
    else
        echo "`pwd`/$(dirname $0)"
    fi
}

myos() {
    echo `uname|tr "[:upper:]" "[:lower:]"`
}

#########################################
###             ARG PARSER            ###
#########################################

usage() {
prog=`basename $0`
cat << EOF

USAGE: $prog [OPTIONS] srcfile dstpath

DESCRIPTION:
    This script aim to generate iOS APP icons more easier and simply.

    srcfile - The source png image. Preferably above 1024x1024
    dstpath - The destination path where the icons generate to.

OPTIONS:
    -h      Show this help message and exit

EXAMPLES:
    $prog 1024.png ~/123

EOF
exit 1
}

while getopts 'h' arg; do
    case $arg in
        h)
            usage
            ;;
        ?)
            # OPTARG
            usage
            ;;
    esac
done

shift $(($OPTIND - 1))

[ $# -ne 2 ] && usage

#########################################
###            MAIN ENTRY             ###
#########################################

cmdcheck sips
src_file=$1
dst_path=$2

# check source file
[ ! -f "$src_file" ] && { error "The source file $src_file does not exist, please check it."; exit -1; }

# check width and height 
src_width=`sips -g pixelWidth $src_file 2>/dev/null|awk '/pixelWidth:/{print $NF}'`
src_height=`sips -g pixelHeight $src_file 2>/dev/null|awk '/pixelHeight:/{print $NF}'`

[ -z "$src_width" ] &&  { error "The source file $src_file is not a image file, please check it."; exit -1; }

if [ $src_width -ne $src_height ];then
    warn "The height and width of the source image are different, will cause image deformation."
fi

# create dst directory 
[ ! -d "$dst_path" ] && mkdir -p "$dst_path"

# ios sizes refer to https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/

# name size
sizes_mapper=`cat << EOF
Icon-App-20x20@1x         20
Icon-App-20x20@2x-1       40
Icon-App-20x20@2x         40
Icon-App-20x20@2x-2       40
Icon-App-20x20@3x         60
Icon-App-29x29@1x         29
Icon-App-29x29@2x         58
Icon-App-29x29@2x-1       58
Icon-App-29x29@3x         87
Icon-App-40x40@2x         80
Icon-App-40x40@2x-1       80
Icon-App-40x40@3x         120
Icon-App-40x40@3x-1       120
Icon-App-60x60@3x         180
Icon-App-76x76@1x         76
Icon-App-76x76@2x         152
Icon-App-83.5x83.5@2x     167
ItunesArtwork@2x         1024
EOF`

OLD_IFS=$IFS
IFS=$'\n'
srgb_profile='/System/Library/ColorSync/Profiles/sRGB Profile.icc'

for line in $sizes_mapper
do
    name=`echo $line|awk '{print $1}'`
    size=`echo $line|awk '{print $2}'`
    info "Generate $name.png ..."
    if [ -f $srgb_profile ];then
        sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -z $size $size $src_file --out $dst_path/$name.png >/dev/null 2>&1
    else
        sips -z $size $size $src_file --out $dst_path/$name.png >/dev/null
    fi
done

info "Congratulation. All icons for iOS APP are generate to the directory: $dst_path."

IFS=$OLD_IFS

