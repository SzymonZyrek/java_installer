#!/bin/bash
UNPACKER_START_DIR=`pwd`
WHAT=$1
WHERE=$2
HOW=$3
mkdir ${WHERE}/tmp
cp $WHAT $WHERE/tmp
cd $WHERE/tmp
DO_UNPACK=$HOW
eval "$DO_UNPACK $WHAT"
rm -rf $WHAT
UNPACKED=`ls`
mv $UNPACKED ..
cd ..
rm -rf tmp
echo "`pwd`/$UNPACKED"
cd $UNPACKER_START_DIR
