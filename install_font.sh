#!/bin/bash

DEST=~/.local/share/fonts
SRC=$1

mkdir -p $DEST

if [ -z $SRC ]; then
	echo "Please specify file."
	exit 1

elif [ ! -e $SRC ]; then
	echo "FIle $SRC does not exist."
	exit 1
elif [[ ! ($SRC == *.zip) ]]; then
	echo "File must be zip."
	exit 1
fi

LEN=${#SRC}
DIR=$(echo $SRC | cut -c 1-$((LEN - 4)) | tr '/' '_')
unzip -qq $SRC -d $DIR

FONTS=$(find $DIR -name '*.ttf')
for FONT in $FONTS
do
	mv $FONT $DEST
done

rm -rf $DIR

