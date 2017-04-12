#
# Cookbook Name:: bcpc
# Recipe:: neutron-head
#
# Copyright 2017, Bloomberg Finance L.P.
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

return unless node['bcpc']['enabled']['neutron']

include_recipe "bcpc::neutron-common"

ruby_block "neutron-database-creation" do
  block do
    %x[ export MYSQL_PWD=#{get_config('mysql-root-password')};
        mysql -uroot -e "CREATE DATABASE #{node['bcpc']['dbname']['neutron']};"
        mysql -uroot -e "GRANT ALL ON #{node['bcpc']['dbname']['neutron']}.* TO '#{get_config('mysql-neutron-user')}'@'%' IDENTIFIED BY '#{get_config('mysql-neutron-password')}';"
        mysql -uroot -e "GRANT ALL ON #{node['bcpc']['dbname']['neutron']}.* TO '#{get_config('mysql-neutron-user')}'@'localhost' IDENTIFIED BY '#{get_config('mysql-neutron-password')}';"
        mysql -uroot -e "FLUSH PRIVILEGES;"
    ]
    self.notifies :run, "bash[neutron-database-sync]", :immediately
    self.resolve_notification_references
  end
  not_if { system "MYSQL_PWD=#{get_config('mysql-root-password')} mysql -uroot -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"#{node['bcpc']['dbname']['neutron']}\"'|grep \"#{node['bcpc']['dbname']['neutron']}\" >/dev/null" }
end

package 'neutron-server' do
  action :upgrade
end

service 'neutron-server' do
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]", :delayed
  subscribes :restart, "template[/etc/neutron/plugins/ml2/ml2_conf.ini]", :delayed
  subscribes :restart, "template[/etc/neutron/policy.json]", :delayed
end

bash "neutron-database-sync" do
  action :nothing
  user "root"
  code "neutron-db-manage upgrade heads"
end

# add Neutron to the service catalog (not encoded in the main catalog due to Neutron
# being a feature-bitted option at present)
network_catalog_entry = {
  'network' => {
    'name' => 'Network Service',
    'project' => 'neutron',
    'description' => 'OpenStack Network Service',
    'ports' => {
      'admin' => 9696,
      'internal' => 9696,
      'public' => 9696
    },
    'uris' => {
      'admin' => '',
      'internal' => '',
      'public' => ''
    }
  }
}

# ruthlessly copied and pasted from the Keystone recipe
network_catalog_entry.each do |svc, svcprops|
  # attempt to delete endpoints that no longer match the environment
  # (keys off the service type, so it is possible to orphan endpoints if you remove an
  # entry from the environment service catalog)
  ruby_block "keystone-delete-outdated-#{svc}-endpoint" do
    block do
      svc_endpoints_raw = execute_in_keystone_admin_context('openstack endpoint list -f json')
      begin
        #puts svc_endpoints_raw
        svc_endpoints = JSON.parse(svc_endpoints_raw)
        #puts svc_endpoints
        svc_ids = svc_endpoints.select { |k| k['Service Type'] == svc }.collect { |v| v['ID'] }
        #puts svc_ids
        svc_ids.each do |svc_id|
          execute_in_keystone_admin_context("openstack endpoint delete #{svc_id} 2>&1")
        end
      rescue JSON::ParserError
      end
    end
    not_if {
      svc_endpoints_raw = execute_in_keystone_admin_context('openstack endpoint list -f json')
      begin
        svc_endpoints = JSON.parse(svc_endpoints_raw)
        next if svc_endpoints.empty?
        svcs = svc_endpoints.select { |k| k['Service Type'] == svc }
        next if svcs.empty?

        adminurl_raw = svcs.select { |v| v['URL'] if v['Interface'] == 'admin' }
        adminurl = adminurl_raw.empty? ? nil : adminurl_raw[0]['URL']
        internalurl_raw = svcs.select { |v| v['URL'] if v['Interface'] == 'internal' }
        internalurl = internalurl_raw.empty? ? nil : internalurl_raw[0]['URL']
        publicurl_raw = svcs.select { |v| v['URL'] if v['Interface'] == 'public' }
        publicurl = publicurl_raw.empty? ? nil : publicurl_raw[0]['URL']

        adminurl_match = adminurl.nil? ? true : (adminurl == generate_service_catalog_uri(svcprops, 'admin'))
        internalurl_match = internalurl.nil? ? true : (internalurl == generate_service_catalog_uri(svcprops, 'internal'))
        publicurl_match = publicurl.nil? ? true : (publicurl == generate_service_catalog_uri(svcprops, 'public'))

        adminurl_match && internalurl_match && publicurl_match
      rescue JSON::ParserError
        false
      end
    }
  end

  # why no corresponding deletion for out of date services?
  # services don't get outdated in the way endpoints do (since endpoints encode version numbers and ports),
  # services just say that service X is present in the catalog, not how to access it

  ruby_block "keystone-create-#{svc}-service" do
    block do
      execute_in_keystone_admin_context("openstack service create --name '#{svcprops['name']}' --description '#{svcprops['description']}' #{svc}")
    end
    only_if {
      services_raw = execute_in_keystone_admin_context('openstack service list -f json')
      services = JSON.parse(services_raw)
      services.select { |s| s['Type'] == svc }.length.zero?
    }
  end

  # openstack command syntax changes between identity API v2 and v3, so calculate the endpoint creation command ahead of time
  identity_api_version = node['bcpc']['catalog']['identity']['uris']['public'].scan(/^[^\d]*(\d+)/)[0][0].to_i
  if identity_api_version == 3
    endpoint_create_cmd = <<-EOH
      openstack endpoint create \
          --region '#{node['bcpc']['region_name']}' #{svc} public "#{generate_service_catalog_uri(svcprops, 'public')}" ;
      openstack endpoint create \
          --region '#{node['bcpc']['region_name']}' #{svc} internal "#{generate_service_catalog_uri(svcprops, 'internal')}" ;
      openstack endpoint create \
          --region '#{node['bcpc']['region_name']}' #{svc} admin "#{generate_service_catalog_uri(svcprops, 'admin')}" ;
    EOH
  else
    endpoint_create_cmd = <<-EOH
      openstack endpoint create \
          --region '#{node['bcpc']['region_name']}' \
          --publicurl "#{generate_service_catalog_uri(svcprops, 'public')}" \
          --adminurl "#{generate_service_catalog_uri(svcprops, 'admin')}" \
          --internalurl "#{generate_service_catalog_uri(svcprops, 'internal')}" \
          #{svc}
    EOH
  end

  ruby_block "keystone-create-#{svc}-endpoint" do
    block do
      execute_in_keystone_admin_context(endpoint_create_cmd)
    end
    only_if {
      endpoints_raw = execute_in_keystone_admin_context('openstack endpoint list -f json')
      endpoints = JSON.parse(endpoints_raw)
      endpoints.select { |e| e['Service Type'] == svc }.length.zero?
    }
  end
end

include_recipe 'bcpc::calico-head'
