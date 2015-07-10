#!/bin/bash
print_line(){
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}
