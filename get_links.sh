#!/bin/bash
STARTING_DIR=`pwd`
SITES_FILE="$STARTING_DIR/SITES"
VERSIONS_FILE_JDK="$STARTING_DIR/JDK_REPOSITORY"
VERSIONS_FILE_JRE="$STARTING_DIR/JRE_REPOSITORY"

source temp_workdirs.sh
setup_temp_workdir "links_getter"

REGEX=i[0-9]86
ARCH=`arch`
if [[ $ARCH =~ $REGEX ]]
then
  ARCH="i586"
elif [[ $ARCH =~ "64" ]]
then
  ARCH="x64"
fi
HEADER=`uname -a`
SOL_REGEX=[sS]ol
LIN_REGEX=[lLinux]
if [[ $HEADER =~ $LIN_REGEX ]]
then
  SYSTEM="linux"
elif [[ $HEADER =~ $SOL_REGEX ]]
then
  SYSTEM="solaris"
else
  SYSTEM="UNKNOWN"
fi

if [[ "$SYSTEM" != "linux" ]]
then
echo "$SYSTEM is not supported"
exit 1
fi

rm -rf 2>/dev/null ALL_LINKS
rm -rf 2>/dev/null $VERSIONS_FILE_JDK
rm -rf 2>/dev/null $VERSIONS_FILE_JRE
#GET ALL DOWNLOAD LINKS
while read LINE
do
  curl 2>/dev/null $LINE | sed -ne 's#.*"filepath":"\(http://download.oracle.com/otn\(-pub\)\?/java/jdk/[-_/a-z0-9]*\(\.tar\.gz\|\.bin\)\).*#\1#p' | grep $SYSTEM | grep $ARCH | grep -v 'rpm'| grep -v 'demos' >> ALL_LINKS
done < $SITES_FILE

while read LINE
do
  FILE=`echo $LINE | sed -e 's#.*/##'`
  DESC=`echo $FILE | sed -e 's/\..*//'`
  JDKORJRE=`echo $DESC | awk 'BEGIN{FS="-"} {print $1}'`
  VERSION=`echo $DESC | awk 'BEGIN{FS="-"} {print $2}'`
  REGEX=[0-9]u[0-9]\+
  if [[ $VERSION =~ $REGEX ]]
  then
    MAJOR_VERSION=`echo $VERSION | sed -e 's/u[0-9]\+//'`
    MINOR_VERSION=`echo $VERSION | sed -e 's/[0-9]u//'`
  else
    MAJOR_VERSION=$VERSION
    MINOR_VERSION="00"
  fi
  URL=`echo $LINE | sed -e 's/otn/otn-pub/'`
  URL=`echo $URL | sed -e 's/otn-pub-pub/otn-pub/'`
  ENTRY="${MAJOR_VERSION}#${MINOR_VERSION}#$URL"
  if [[ $JDKORJRE = "jdk" ]]
  then
    echo $ENTRY >> $VERSIONS_FILE_JDK
  elif [[ $JDKORJRE = "jre" ]]
    then
    echo $ENTRY >> "$VERSIONS_FILE_JRE"
  fi
done < ALL_LINKS
  #cat $VERSIONS_FILE_JDK | sort | uniq > $VERSIONS_FILE_JDK
  #cat $VERSIONS_FILE_JRE | sort | uniq > $VERSIONS_FILE_JRE
cd $STARTING_DIR
destroy_temp_workdir
