#!/bin/bash
TEMP_DIRS_ROOT=/tmp
NO_REMOVE="n"
SILENT="y"
#READS ONLY ONE POSSIBLE OPTION: -r|--root wihch overrides /tmp
#as the base root for temporary workdirs
while [[ $# > 0 ]]
do
key="$1"

shift 
done

START_DIR=~/
setup_temp_workdir(){
  START_DIR=`pwd`
  WORKDIR_NAME="default"
  if [[ $1 != "" ]]
  then
    WORKDIR_NAME=$1
  fi
  WORK_DIR=$TEMP_DIRS_ROOT/$WORKDIR_NAME
  if [[ "$SILENT" != "y" ]]
  then
    echo "Creating temporary directory $WORK_DIR"
  fi
  mkdir -p $WORK_DIR
  cd $WORK_DIR
}
destroy_temp_workdir(){
  if [[ $1 != "" ]]
  then
    WORKDIR_NAME=$1
  fi
  if [[ "$NO_REMOVE" == "y" ]]
  then
    echo ""
  else
    if [[ "$SILENT" != "y" ]]
    then
      echo "Removing temporary directory $WORK_DIR"
    fi
    cd $START_DIR
    rm -rf $WORK_DIR
  fi
}
