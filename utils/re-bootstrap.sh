rsync -axSHvP -e 'ssh -ostricthostkeychecking=no -i vbox/insecure_private_key' --exclude vbox --exclude vmware --exclude vbox/insecure_private_key --exclude .chef . vagrant@10.0.100.3:chef-bcpc

SSH_CMD='vagrant ssh -c'
BCPC_DIR=chef-bcpc
IP=10.0.100.3
CHEF_ENVIRONMENT=Test-Laptop
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_bootstrap_node.sh ${IP} ${CHEF_ENVIRONMENT}"
