#
# Cookbook Name:: keepalived
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

package "keepalived"

if node['keepalived']['shared_address']
  file '/etc/sysctl.d/60-ip-nonlocal-bind.conf' do
    mode 0644
    content "net.ipv4.ip_nonlocal_bind=1\n"
    notifies :start, "service[procps]", :immediately
  end

  service 'procps' do
    action :nothing
  end
end

template "keepalived.conf" do
  path "/etc/keepalived/keepalived.conf"
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

case node["keepalived"]["init_style"]
when "init"
  template "/etc/init.d/keepalived" do
    source "init.erb"

    owner "root"
    group "root"
    mode "0755"
  end

  service "keepalived" do
    supports :restart => true, :status => true
    action [:enable, :start]
    subscribes :restart, "template[keepalived.conf]"
  end
when "runit"
  service "keepalived_init" do
    service_name "keepalived"
    # Find a "normal" daemonized keepalived process.
    # runit processes are run as children of runsv
    status_command "pgrep -P 1 -f '^/usr/sbin/keepalived(\s+|$)'"
    # We keep the init service enable to please dependent services in insserv
    # Yes, I know this is braindead but it works...
    action [:stop, :enable]
  end

  include_recipe "runit"
  runit_service "keepalived" do
    owner "root"
    group "root"

    default_logger true

    action [:enable, :start]
    subscribes :hup, "template[keepalived.conf]"
  end
end
