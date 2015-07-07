#!/bin/bash
STARTING_DIR=`pwd`
#CHECK DEFAULT
source temp_workdirs.sh
setup_temp_workdir "test"
if [[ `find /tmp -type d -name test | wc -l` -ne 1 ]]
then
  echo "ERROR: can't find created workdir /tmp/test"
fi
if [[ `pwd` != "/tmp/test" ]]
then
   echo "ERROR: i should be in workdir /tmp/test, instead im in `pwd`"
fi
destroy_temp_workdir
if [[ `find /tmp -type d -name test | wc -l` -ne 0 ]]
then
  echo "ERROR: workdir /tmp/test not properly destroyed"
fi
if [[ `pwd` != $STARTING_DIR ]]
then
   echo "ERROR: i should be back where i started in $STARTING_DIR, instead im in `pwd`"
fi
source temp_workdirs.sh --root $STARTING_DIR/temporary
setup_temp_workdir "test2"
if [[ `find $STARTING_DIR/temporary -type d -name test2 | wc -l` -ne 1 ]]
then
  echo "ERROR: can't find created workdir $STARTING_DIR/temporary/test2"
fi
if [[ `pwd` != "$STARTING_DIR/temporary/test2" ]]
then
   echo "ERROR: i should be in workdir $STARTING_DIR/temporary/test2, instead im in `pwd`"
fi
destroy_temp_workdir

if [[ `find $STARTING_DIR/temporary -type d -name test2 | wc -l` -ne 0 ]]
then
  echo "ERROR: workdir $STARTING_DIR/temporary/test2 not properly destroyed"
fi
if [[ `pwd` != $STARTING_DIR ]]
then
   echo "ERROR: i should be back in $STARTING_DIR, instead im in `pwd`"
fi
rm -rf $STARTING_DIR/temporary

