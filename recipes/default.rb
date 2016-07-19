#
# Cookbook Name:: ohai
# Recipe:: default
#
# Copyright 2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if !Ohai::Config[:plugin_path].include?(node['ohai']['plugin_path'])
  Ohai::Config[:plugin_path] << node['ohai']['plugin_path']
end
Chef::Log.info("ohai plugins will be at: #{node['ohai']['plugin_path']}")

if Gem.win_platform?
	$admin_user = ENV["USERNAME"]
	$admin_group = Ohai::Util::Win32::GroupHelper.windows_root_group_name
else
	$admin_user = 'root'
	$admin_group = 'root'
end

rd = remote_directory node['ohai']['plugin_path'] do
  source 'plugins'
  owner $admin_user
  group $admin_group
  mode 0755
  recursive true
  action :nothing
end

rd.run_action(:create)

# only reload ohai if new plugins were dropped off OR
# node['ohai']['plugin_path'] does not exists in client.rb
if rd.updated? || 
  !(::IO.read(Chef::Config[:config_file]) =~ /Ohai::Config\[:plugin_path\]\s*<<\s*["']#{node['ohai']['plugin_path']}["']/)

  ohai 'custom_plugins' do
    action :nothing
  end.run_action(:reload)

end
