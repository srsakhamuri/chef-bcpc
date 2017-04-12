# Calico networking configuration

# attributes in here apply only if bcpc.enabled.neutron is true
default['bcpc']['calico']['fixed_network']['name'] = 'calico_int_net'
default['bcpc']['calico']['fixed_network']['subnet'] = '192.168.101.0/24'
