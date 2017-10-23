#!/bin/bash
hash -r

dir="$( cd "${0%/*}" && env pwd -P )"
statedir="${BCPC_DIR:-$dir}/vbox"

for i in bcpc-{bootstrap,vm{1..3}} ; do
  VBoxManage controlvm $i poweroff 2>/dev/null
  VBoxManage unregistervm $i --delete 2>/dev/null
  if [ -d "${statedir}/${i}" ] ; then
    echo "Forcibly removing ${i} VM state directory" >&2
    rm -rf "${statedir}/${i}"
  fi
done
