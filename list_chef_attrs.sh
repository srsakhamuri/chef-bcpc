#!/bin/bash 

usage(){
  cat <<HeLP > /dev/stderr
${0##*/} attribute_name
HeLP
  exit ${1:-0}
}

[ -z "$1" ] && usage 1
read args <<EoF
cd chef-bcpc && knife node show \$(hostname -f) -a $1
EoF
vagrant ssh -c "${args}"
