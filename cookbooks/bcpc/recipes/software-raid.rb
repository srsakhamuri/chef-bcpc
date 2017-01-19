#
# Cookbook Name:: bcpc
# Recipe:: software_raid
#
# Copyright 2015, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node['bcpc']['software_raid']['enabled']
  package 'mdadm'

  # installing mdadm drags Postfix along, disable it
  service 'postfix' do
    action [:stop, :disable]
  end

  service 'mdadm' do
    action [:start, :enable]
  end

  template '/etc/mdadm/mdadm.conf' do
    source 'software-raid.mdadm.conf.erb'
    owner  'root'
    group  'root'
    mode   00644
    variables ({
      :devices   => node['bcpc']['software_raid']['devices'],
      :md_device => node['bcpc']['software_raid']['md_device']
    })
    notifies :restart, 'service[mdadm]', :immediately
    notifies :run, 'bash[update-initramfs]', :delayed
  end

  # this script is executed by the Zabbix agent to test ephemeral volume health
  # (mdadm does not indicate RAID 0 array failure even when drives fail, so
  # I am using a functional test instead)
  cookbook_file '/usr/local/bin/ephemeral_functional_test.sh' do
    source 'ephemeral_functional_test.sh'
    owner  'root'
    group  'root'
    mode   00755
  end

  # Deprecated - check will run as root via cron
  file '/etc/sudoers.d/zabbix_sudoers' do
    action :delete
  end

  cron_cmd = "zabbix_sender -c /etc/zabbix/zabbix_agentd.conf \
             --key ephemeral.health \
             --value \
             `/usr/local/bin/ephemeral_functional_test.sh nova_disk 2>&1`"
  cron 'check_ephemeral_functional' do
    home '/var/lib/zabbix'
    user 'root'
    minute '*/2'
    path '/usr/local/bin:/usr/bin:/bin'
    command cron_cmd
  end

  mdadm node['bcpc']['software_raid']['md_device'] do
    devices node['bcpc']['software_raid']['devices']
    level 0
    metadata '1.2'
    chunk node['bcpc']['software_raid']['chunk_size']
    action [:create, :assemble]
  end

  bash 'update-initramfs' do
    code 'update-initramfs -k all -u'
    action :nothing
  end
end
