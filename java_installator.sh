#!/bin/bash

#DEFAUTLS
MODE="HELP"
INSTALL_TYPE="jdk"
VERSION_STRING="1.8"
SCRIPT_ROOT_DIR=`pwd`
VERSIONS_FILE="`pwd`/VERSIONS"
TARGET_DIR=/usr/lib/jvm
SITES_FILE="`pwd`/SITES"
ALLVER_FILE=allver
ARCHVER_FILE=archver
ALLURLS_FILE=allurls
FILTER=""
DONT_ASK_ALTERNATIVES="n"
DONT_ASK_BASHRC="n"
DONT_ASK_WARNING="n"
DO_BASHRC="n"
DO_ALTERNATIVES="n"
DONT_ASK="n"

#STATE VARIABLES
DOWNLOAD_STARTED=false

#FUNCTIONS
print_usage() {
  print_line
  echo "This program installs jdk on your machine. Usage: ./javaInstalator.sh -i|--install <VERSION>"
  print_line
  echo "Options:"
  echo ""
  echo "	-f|--fetch		: get all avaiable jdk versions from oracle"
  echo "	-l|--list		: list all avaiable jdk versions"
  echo "	-s|--search <STRING>	: filter avaiable jdk versions"
  echo "	-d|--jdk <VERSION>	: installs selected <VERSION> of jdk"
  echo "	-r|--jre <VERSION>	: installs selected <VERSION> of jre (NOT YET WORKING, FOR NOW ALSO INSTALLS JDK^^)"
  echo "	-t|--target		: outpuf folder, where to install?"
  echo "	-b|--bashrc		: adds \$JAVA_HOME to ~/.bashrc"
  echo "	-B|--no-bashrc		: doesn't add \$JAVA_HOME to ~/.bashrc"
  echo "	-u|--alternatives	: updates alternatives"
  echo "	-B|--no-alternatives	: doesn't update alternatives"
  echo "	-W|--no-warn		: don't warn about default target"
  echo "	-S|--silent		: skip all warnings and dialogues"
  echo "	-h|--help		: print this helpful message"
  print_line
}

fetch_versions(){
  cd $SCRIPT_ROOT_DIR
  rm -rf 2>/dev/null $VERSIONS_FILE
  source get_links.sh
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
  CMD="wget --quiet --show-progress --no-check-certificate --no-cookies --header \"Cookie: oraclelicense=accept-securebackup-cookie\"" 
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
    -W|--no-warn)
    DONT_ASK_WARNING="y"
    ;;
    -b|--bashr)
    DO_BASHRC="y"
    DONT_ASK_BASHRC="y"
    ;;
    -B|--no-bashrc)
    DO_BASHRC="n"
    DONT_ASK_BASHRC="y"
    ;;
    -u|--alternatives)
    DO_ALTERNATIVES="y"
    DONT_ASK_ALTERNATIVES="y"
    ;;
    -U|--no-alternatives)
    DO_ALTERNATIVES="n"
    DONT_ASK_ALTERNATIVES="y"
    ;;
    -h|--help)
    MODE="HELP"
    ;;
    -S|--silent)
    DONT_ASK_ALTERNATIVES="y"
    DONT_ASK_BASHRC="y"
    DONT_ASK="y"
    ;;
    -t|--target)
    TARGET_DIR=$2
    shift
    ;;
    -f|--fetch)
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
    -d|--jdk)
    VERSION_STRING="$2"
    MODE="INSTALL"
    INSTALL_TYPE="jdk"
    shift
    ;;
    -r|--jre)
    VERSION_STRING="$2"
    MODE="INSTALL"
    INSTALL_TYPE="jre"
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
source utils.sh
setup_temp_workdir "java_installator"
DOWNLOAD_STARTED=true
if [[ -e $VERSIONS_FILE ]]
then
  VERSIONS_COUNT=`cat $VERSIONS_FILE | wc -l`
  if [[ $VERSIONS_COUNT -gt 0 ]]
  then
    echo ""
  else
    print_line
    echo "Your VERSIONS file is empty, would you like to fetch avaiable versions now?(y/n)"
    print_line
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
  print_line
  echo "You do not have VERSIONS file, would you like to fetch avaiable versions now?(y/n)"
  print_line 
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
  print_line
  echo "Fetched $COUNT versions into $VERSIONS_FILE"
  print_line
elif [[ "$MODE" == "HELP" ]]
then
  print_usage
  terminate 0
elif [[ "$MODE" == "LIST_VERSIONS" ]]
then
  print_line
  echo "Avaiable versions:"
  print_line
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
  if [[ $TARGET_DIR == "/usr/lib/jvm" && $DONT_ASK_WARNING != "y" && $DONT_ASK != "y" ]]
  then
    print_line
    echo "WARNINIG: you haven't selected --target installation directory, default value is /usr/lib/jvm. Is this ok?(y/n)"
    print_line
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
    print_line
    echo "Avaiable sub-releases for version 1.$VERSIO: "
    print_line
    echo $AVAIABLE_RELEASES | sed -e "s/\([0-9][0-9]\?\)/\n\t1.${VERSION}.0_\1/g"
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
    print_line
    echo "Unpacking $DOWNLOADED_FILE to $TARGET_DIR"
    print_line
    UNPACKED_FILE_NAME=`sudo ${SCRIPT_ROOT_DIR}/unpacker.sh $DOWNLOADED_FILE $TARGET_DIR "tar -xzf "`
  elif [[ "$DOWNLOADED_FILE" =~ ".bin" ]]
  then
    print_line
    echo "Installing $DOWNLOADED_FILE to $TARGET_DIR"
    print_line
    sudo chmod +x ${DOWNLOADED_FILE}
    UNPACKED_FILE_NAME=`sudo ${SCRIPT_ROOT_DIR}/unpacker.sh $DOWNLOADED_FILE $TARGET_DIR "yes | sudo ./"` 
    sudo rm -rf 2>/dev/null ${DOWNLOADED_FILE}
  else
    echo "Broken file: $DOWNLOADED_FILE"
    terminate 1
  fi
  
#CONFIGURATION
  JAVA_DIR=$UNPACKED_FILE_NAME
  print_line
  printf "JDK 1.${VERSION}.0_${UPDATE} installed at $JAVA_DIR\n"
  print_line
  #JAVA_HOME
  if [[ $DONT_ASK != "y" && $DONT_ASK_BASHRC != "y" ]]
  then
    echo "Set \$JAVA_HOME in ~/.bashrc?(y/n)"
    ANSWER=$(read_yes_no)
    if [[ "$ANSWER" == "y" ]]
    then
      DO_BASHRC="y"
    fi
  fi
  print_line
  if [[ $DO_BASHRC == "y" ]]
  then
    echo "Setting \$JAVA_HOME to $JAVA_DIR"
    echo "export JAVA_HOME=$JAVA_DIR" >> ~/.bashrc
  else
    echo "Skipping \$JAVA_HOME configuration"
  fi
  print_line
  #UPDATE-ALTERNATIVES
  if [[ $DONT_ASK != "y" && $DONT_ASK_ALTERNATIVES != "y" ]]
  then
    echo "Update alternatives?(y/n)"
    ANSWER2=$(read_yes_no)
    if [[ "$ANSWER2" == "y" ]]
    then
      DO_ALTERNATIVES="y"
    fi
  fi
  print_line
  if [[ $DO_ALTERNATIVES == "y" ]]
    then
      echo "sudo update-alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 1"
      echo "sudo update-alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 1"
      sudo update-alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 1
      sudo update-alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 1
    else
      echo "Skipping update-alternatives configuration"
  fi
  print_line
  terminate 0
fi
