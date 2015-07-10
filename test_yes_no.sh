#!/bin/bash
source yes_no.sh
VAR=`yes | read_yes_no`
echo 'yes_no.sh test:'
if [[ "$VAR" == "y" ]]
then
echo '		SUCCESSFUL'
else
echo '		FAILED'
fi
