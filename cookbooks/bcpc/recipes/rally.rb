#
# Cookbook Name:: bcpc
# Recipe:: rally
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

# This recipe simply installs rally on the given node (bootstrap by default). The rally-setup.rb will set rally
# up to be able to be ran.
apt_repository 'mitaka-staging-rally' do
  uri node['bcpc']['repos']['mitaka-staging']
  distribution node['lsb']['codename']
  components ['main']
  key 'ubuntu-cloud-archive-mitaka-staging-trusty.key'
end

package 'rally' do
  action :upgrade
end

template "/etc/rally/rally.conf" do
    source "rally.conf.erb"
    owner node['bcpc']['rally']['user']
    group node['bcpc']['rally']['user']
    mode 0664
end

# Remove old local rally installation remnants
#  - just leave stuff in /opt/rally.. it's in /opt!
bins = %w{ rally-manage rally }
install_dir = '/usr/local/bin'
lib_dir = '/usr/local/lib/python2.7/dist-packages/rally'
bins.each do |bin|
  path = File.join(install_dir, bin)
  file path do
    action :delete
  end
end

directory lib_dir do
  recursive true
  action :delete
end
