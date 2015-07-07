#!/bin/bash

#DEFAUTLS
MODE="HELP"
VERSION_STRING="1.8"
SCRIPT_ROOT_DIR=`pwd`
VERSIONS_FILE="`pwd`/VERSIONS"
TARGET_DIR=/usr/lib/jvm
SITES_FILE="`pwd`/SITES"
ALLVER_FILE=allver
ARCHVER_FILE=archver
ALLURLS_FILE=allurls
FILTER=""

#STATE VARIABLES
DOWNLOAD_STARTED=false

#FUNCTIONS
print_usage() {
  echo "This program installs jdk on your machine. Usage: ./javaInstalator.sh -v <VERSION>"
}

fetch_versions(){
  cd $SCRIPT_ROOT_DIR
  rm -rf 2>/dev/null $VERSIONS_FILE
  source get_links.sh
  cp JDK_REPOSITORY $VERSIONS_FILE
}

terminate(){
  if [[ $DOWNLOAD_STARTED == true ]]
  then
    destroy_temp_workdir "java_installator"
  fi
  exit $1
}
#TRAPPING CRTL-C TO DELETE
#TEMP FILES
trap terminate SIGINT

download_java_from_url(){
  CMD="wget --no-check-certificate --no-cookies --header \"Cookie: oraclelicense=accept-securebackup-cookie\"" 
  CMD+=" $1"
  eval $CMD
}

get_package_url_for_version_and_update(){
  while read LINE
  do
    VERSION=`echo $LINE | awk 'BEGIN{FS="#"}{print $1}'`
    UPDATE=`echo $LINE | awk 'BEGIN{FS="#"}{print $2}'`
    URL=`echo $LINE | awk 'BEGIN{FS="#"}{print $3}'`
    if [[ "$VERSION" == "$1" ]]
    then
      if [[ "$2" == "$UPDATE" ]]
      then
        echo $URL
      fi
    fi
  done < $VERSIONS_FILE
}

get_avaiable_sub_versions_for_version(){
  declare -a MATCHES=()
  COUNTER=0
  while read LINE
  do
    VERSION=`echo $LINE | awk 'BEGIN{FS="#"}{print $1}'`
    UPDATE=`echo $LINE | awk 'BEGIN{FS="#"}{print $2}'`
    if [[ "$VERSION" == "$1" ]]
    then
      MATCHES[$COUNTER]=$UPDATE
      COUNTER=$((COUNTER+1))
    fi
  done < $VERSIONS_FILE
  echo ${MATCHES[*]} | sed -e 's/ /\n/'
}


#PARSE ARGS
while [[ $# > 0 ]]
do
key="$1"
case $key in
    -h|--help)
    MODE="HELP"
    ;;
    -t|--target)
    TARGET_DIR=$2
    shift
    ;;
    -f|--fetch-versions)
    MODE="FETCH_VERSIONS"
    ;;
    -s|--search)
    MODE="LIST_VERSIONS"
    FILTER="$2"
    shift
    ;;
    -l|--list)
    MODE="LIST_VERSIONS"
    ;;
    -v|--version)
    VERSION_STRING="$2"
    MODE="INSTALL"
    shift
    ;;
    *)
    echo "ERROR: Unknown option $1";
    MODE="HELP"
    ;;
esac
shift
done


#SOURCE DEPENDENCIES
source temp_workdirs.sh
source yes_no.sh
setup_temp_workdir "java_installator"
DOWNLOAD_STARTED=true
if [[ -e $VERSIONS_FILE ]]
then
  VERSIONS_COUNT=`cat $VERSIONS_FILE | wc -l`
  if [[ $VERSIONS_COUNT -gt 0 ]]
  then
    echo ""
  else
    echo "Your VERSIONS file is empty, would you like to fetch avaiable versions now?(y/n)"
    ANSWER=$(read_yes_no)
    if [[ "$ANSWER" == "y" ]]
    then
      MODE="FETCH_VERSIONS"
    else
      echo "ERROR: no versions avaiable, exiting"
      terminate 1
    fi
  fi
else
  echo "You do not have VERSIONS file, would you like to fetch avaiable versions now?(y/n)"
  ANSWER=$(read_yes_no)
  if [[ "$ANSWER" == "y" ]]
  then
    MODE="FETCH_VERSIONS"
  else
    echo "ERROR: no versions avaiable, exiting"
    terminate 1
  fi
fi

if [[ "$MODE" == "FETCH_VERSIONS" ]]
then
  fetch_versions
  COUNT=`cat $VERSIONS_FILE | wc -l`
  echo "Fetched $COUNT versions into $VERSIONS_FILE"
elif [[ "$MODE" == "HELP" ]]
then
  print_usage
  terminate 0
elif [[ "$MODE" == "LIST_VERSIONS" ]]
then
  echo "Avaiable versions:"
  while read LINE
  do
    VERSION=`echo $LINE | awk 'BEGIN{FS="#"}{print $1}'`
    UPDATE=`echo $LINE | awk 'BEGIN{FS="#"}{print $2}'`
    VSTRING="1.${VERSION}.0_${UPDATE}"
    if [[ "$FILTER" == "" ]]
    then
      echo "	$VSTRING"
    elif [[ $VSTRING =~ $FILTER ]]
    then
      echo "	$VSTRING"
    fi
  done < $VERSIONS_FILE
  terminate 0
elif [[ "$MODE" == "INSTALL" ]]
then
  #WARN IF DEAFAULT TARGET
  if [[ $TARGET_DIR == "/usr/lib/jvm" ]]
  then
    echo "WARNINIG: you haven't selected --target installation directory, default value is /usr/lib/jvm. Is this ok?(y/n)"
    ANSWER=$(read_yes_no)
    if [[ "$ANSWER" == "n" ]]
    then
      terminate 0;
    fi
  fi
  #PARSE REQUESTED VERSION
  if [[ `echo $VERSION_STRING | sed -e '/^\(1\.\)\?\([4-8]\)\(\.[0-9]_\([0-9][0-9]\)\)\?\(-[a-z][a-z]\)\?$/d' | wc -l` -eq 0 ]]
  then
    V_STRING_PROP=`echo $VERSION_STRING | sed -e 's/^\(1\.\)\?\([4-8]\)\(\.[0-9]_\([0-9][0-9]\)\)\?\(-[a-z][a-z]\)\?$/VERSION:\2,UPDATE:\4/'`
    VERSION=`echo $V_STRING_PROP | sed -e 's/VERSION:\([^,]*\),.*/\1/'`
    UPDATE=`echo $V_STRING_PROP | sed -e 's/.*UPDATE:\(.*\)$/\1/'`
  else
    echo "ERROR: Unrecognised version $VERSION_STRING, exiting"
    terminate 1
  fi
  #FILL SUB-VERSION (UPDATE) IF NEEDED
  if [[ "$UPDATE" == "" ]]
  then
    declare -a AVAIABLE_RELEASES=`get_avaiable_sub_versions_for_version $VERSION`
    echo "Avaiable sub-releases for version 1.$VERSIO: "
    echo $AVAIABLE_RELEASES | sed -e "s/\([0-9][0-9]\)/\n\t1.${VERSION}.0_\1/g"
    echo 
    echo "please pick one now by typing update number (last 2 digits)"
    while [[ "$UPDATE" == "" ]]
    do
      read LINE
      CHOICES=$(echo $AVAIABLE_RELEASES | tr " " "\n")
      for CHOICE in $CHOICES
      do
        if [[ $CHOICE =~ $LINE ]]
        then
          UPDATE=$CHOICE
        fi
      done
    done
  fi
  
#ACTUAL INSTALLATION
  #SETUP TEMPORARY WORK DIRECTORY 
  #AND DOWNLOAD REQUESTED VERSION
  DOWNLOAD_URL=`get_package_url_for_version_and_update $VERSION $UPDATE`
  if [[ "$DOWNLOAD_URL" == "" ]]
  then
    echo "ERROR: Unrecognised version $VERSION_STRING"
    terminate 1
  fi
  download_java_from_url $DOWNLOAD_URL

  #UNPACK
  DOWNLOADED_FILE=`echo $DOWNLOAD_URL | sed -e 's#.*/##'`
  sudo mkdir -p 2>/dev/null $TARGET_DIR
  if [[ "$DOWNLOADED_FILE" =~ ".tar.gz" ]]
  then
    echo "Unpacking $DOWNLOADED_FILE to $TARGET_DIR"
    UNPACKED_FILE_NAME=`sudo ${SCRIPT_ROOT_DIR}/unpack_and_echo_path.sh $DOWNLOADED_FILE $TARGET_DIR "tar -xzf"`
  elif [[ "$DOWNLOADED_FILE" =~ ".bin" ]]
  then
    echo "Moving $DOWNLOADED_FILE to $TARGET_DIR"
    sudo mv $DOWNLOADED_FILE $TARGET_DIR/
    cd $TARGET_DIR
    sudo chmod +x ${DOWNLOADED_FILE}
    sudo ${TARGET_DIR}/${DOWNLOADED_FILE}
    UNPACKED_FILE_NAME=`sudo ${SCRIPT_ROOT_DIR}/unpack_and_echo_path.sh ""` 
    sudo rm -rf 2>/dev/null ${TARGET_DIR}/${DOWNLOADED_FILE}
  else
    echo "Broken file: $DOWNLOADED_FILE"
    terminate 1
  fi
  
#CONFIGURATION
  JAVA_DIR=$UNPACKED_FILE_NAME
  printf "JDK 1.${VERSION}.0_${UPDATE} installed at $JAVA_DIR\n"
  #JAVA_HOME
  echo "Set \$JAVA_HOME in ~/.bashrc?(y/n)"
  ANSWER=$(read_yes_no)
  if [[ "$ANSWER" == "y" ]]
  then
    echo "Setting \$JAVA_HOME to $JAVA_DIR"
    echo "export JAVA_HOME=$JAVA_DIR" >> ~/.bashrc
  else
    echo "Skipping \$JAVA_HOME configuration"
  fi
  #UPDATE-ALTERNATIVES
  echo "Update alternatives?(y/n)"
  ANSWER2=$(read_yes_no)
  if [[ "$ANSWER2" == "y" ]]
  then
    sudo update-alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 1
    sudo update-alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 1
  else
    echo "Skipping update-alternatives configuration"
  fi
  terminate 0
fi
