rsync -axSHvP -e 'ssh -ostricthostkeychecking=no -i vbox/insecure_private_key' --exclude vbox --exclude vmware --exclude vbox/insecure_private_key --exclude .chef . vagrant@10.0.100.3:chef-bcpc
