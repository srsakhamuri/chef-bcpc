#/bin/bash

hash -r
set -e

dir="$(git rev-parse --show-toplevel)" || exit 2
keyfile="$(
  cd "${dir}/bootstrap/vagrant_scripts"
  vagrant ssh-config vm-bootstrap | awk '/Host vm-bootstrap/,/^$/{ if ($0 ~ /^ +IdentityFile/) print $2}'
)"
rsync -axSHvP -e "ssh -ostricthostkeychecking=no -i ${keyfile}" --exclude vbox --exclude vmware --exclude vbox/insecure_private_key --exclude .chef . vagrant@10.0.100.3:chef-bcpc
