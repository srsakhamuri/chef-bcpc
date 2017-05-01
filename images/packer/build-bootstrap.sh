#!/bin/bash
keyfile="bootstrap_chef.id_rsa"
rm "${keyfile}"*
ssh-keygen -N "" -f "$keyfile"
cp "${keyfile}".pub files
cp "${keyfile}" ../..

u_series=trusty
u_url="http://archive.ubuntu.com/ubuntu/dists/$u_series-updates/main/installer-amd64/current/images"
u_checksum=$(curl --progress -s -f -L $u_url/SHA256SUMS | awk -v f=./netboot/mini.iso '$2 == f { print $1 }')

# Inject the upstream checksum into the .json, so it always matches what we downloaded
# This removes the need to update the .json by-hand to keep the checksum current
sed -i 's/"iso_checksum":.*/"iso_checksum": "'"$u_checksum"'",/' bcpc-bootstrap.json

# Or, if you want to use jq instead of sed
# jq ".builders[].iso_checksum |= \"$ubuntu_checksum\"" bcpc-bootstrap.json > bcpc-bootstrap-output.json

packer build bcpc-bootstrap.json
# packer build bcpc-bootstrap-output.json
