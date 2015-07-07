#!/bin/bash
read_yes_no(){
  ANSWER=""
  YES_OR_NO=^[yYnN]\([oO]\|[eE][sS]\|eah\|eap\|ope\|ah\)?$
  YES=^[yY]\([eE][sS]\|eah\|eap\)?$
  NO=^[nN]\([oO]\|ope\|ah\)?$
  while ! [[ $ANSWER =~ $YES_OR_NO ]]
  do  
    read ANSWER
    if [[ $ANSWER =~ $YES ]]
    then
      echo "y"
    elif [[ $ANSWER =~ $NO ]]
    then
      echo "n"  
    fi
  done
}

