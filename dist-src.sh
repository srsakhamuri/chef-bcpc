keyfile=/Users/bcpc/build/chef-bcpc/bootstrap/vagrant_scripts/.vagrant/machines/bootstrap/virtualbox/private_key
rsync -axSHvP -e "ssh -ostricthostkeychecking=no -i ${keyfile}" --exclude vbox --exclude vmware --exclude vbox/insecure_private_key --exclude .chef . vagrant@10.0.100.3:chef-bcpc
