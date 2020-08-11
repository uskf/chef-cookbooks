#
# Cookbook:: uskf_ovirtgluster
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

# prepare upgrade to oVirt 4.2
execute 'yum -y install https://resources.ovirt.org/pub/yum-repo/ovirt-release42.rpm' do
  only_if { ::File.exist?('/usr/sbin/nodectl') }
  only_if "imgbase w 2>&1 | grep 'You are on ovirt-node-ng-4.1'"
  not_if "hosted-engine --vm-status | grep 'You must run deploy first'"
  not_if { ::File.exist?('/etc/yum.repos.d/ovirt-4.2.repo') }
end

# prepare upgrade to oVirt 4.3
execute 'yum -y install https://resources.ovirt.org/pub/yum-repo/ovirt-release43.rpm' do
  only_if { ::File.exist?('/usr/sbin/nodectl') }
  only_if "imgbase w | grep 'You are on ovirt-node-ng-4.2'"
  not_if { ::File.exist?('/etc/yum.repos.d/ovirt-4.3.repo') }
end

if File.exist?('/etc/yum.repos.d/ovirt-4.1-dependencies.repo')
  file "disable old repo 'ovirt-4.1-dependencies' after upgrade to oVirt 4.2" do
    path '/etc/yum.repos.d/ovirt-4.1-dependencies.repo'
    f = Chef::Util::FileEdit.new(path)
    f.search_file_replace_line(/^enabled=1/, "enabled=0\n")
    content f.send(:editor).lines.join
    only_if "imgbase w | grep 'You are on ovirt-node-ng-4.2'"
  end
end

if File.exist?('/etc/yum.repos.d/ovirt-4.1.repo')
  file "disable old repo 'ovirt-4.1' after upgrade to oVirt 4.2" do
    path '/etc/yum.repos.d/ovirt-4.1.repo'
    f = Chef::Util::FileEdit.new(path)
    f.search_file_replace_line(/^enabled=1/, "enabled=0\n")
    content f.send(:editor).lines.join
    only_if "imgbase w | grep 'You are on ovirt-node-ng-4.2'"
  end
end

if File.exist?('/etc/yum.repos.d/ovirt-4.2-dependencies.repo')
  file "disable old repo 'ovirt-4.2-dependencies' after upgrade to oVirt 4.3" do
    path '/etc/yum.repos.d/ovirt-4.2-dependencies.repo'
    f = Chef::Util::FileEdit.new(path)
    f.search_file_replace_line(/^enabled=1/, "enabled=0\n")
    content f.send(:editor).lines.join
    only_if "imgbase w | grep 'You are on ovirt-node-ng-4.3'"
  end
end

if File.exist?('/etc/yum.repos.d/ovirt-4.2.repo')
  file "disable old repo 'ovirt-4.2' after upgrade to oVirt 4.3" do
    path '/etc/yum.repos.d/ovirt-4.2.repo'
    f = Chef::Util::FileEdit.new(path)
    f.search_file_replace_line(/^enabled=1/, "enabled=0\n")
    content f.send(:editor).lines.join
    only_if "imgbase w | grep 'You are on ovirt-node-ng-4.3'"
  end
end

# setup thick-host from scratch
case node['platform_version']
when /^7.*/
  execute 'yum -y install https://resources.ovirt.org/pub/yum-repo/ovirt-release43.rpm' do
    not_if 'rpm -q ovirt-release43'
    not_if 'ls /usr/sbin/nodectl'
    notifies :run, 'execute[yum makecache]', :immediately
    notifies :run, 'ruby_block[package-reload]', :immediately
  end
when /^8.*/
  execute 'dnf -y install https://resources.ovirt.org/pub/yum-repo/ovirt-release44.rpm' do
    not_if 'rpm -qa | grep ovirt-release44' # avoid packag name bug
    not_if 'ls /usr/sbin/nodectl'
    notifies :run, 'execute[yum makecache]', :immediately
    notifies :run, 'ruby_block[package-reload]', :immediately
  end
end

execute 'yum makecache' do
  action :nothing
end

ruby_block 'package-reload' do
  block do
    if node['platform_version'].to_i >= 8
      Chef::Provider::Package::Dnf::PythonHelper.instance.restart
    else
      Chef::Provider::Package::Yum::YumCache.instance.reload
    end
  end
  action :nothing
end

# update ended repository address to backup site
if File.exist?('/etc/yum.repos.d/ovirt-4.1-dependencies.repo')
  file '/etc/yum.repos.d/ovirt-4.1-dependencies.repo' do
    f = Chef::Util::FileEdit.new(path)
    f.search_file_replace_line(
      %r{http://mirror.centos.org/centos/7/storage/\$basearch/gluster-3.8/$},
      "baseurl=https://buildlogs.centos.org/centos/7/storage/$basearch/gluster-3.8/\n")
    f.search_file_replace_line(
      %r{http://mirror.centos.org/centos/\$releasever/virt/\$basearch/ovirt-4.1/$},
      "baseurl=https://buildlogs.centos.org/centos/$releasever/virt/$basearch/ovirt-4.1/\n")
    f.search_file_replace_line(
      %r{http://mirror.centos.org/centos/\$releasever/opstools/\$basearch/$},
      "baseurl=https://buildlogs.centos.org/centos/$releasever/opstools/$basearch/\n")
    content f.send(:editor).lines.join
    only_if "imgbase w 2>&1| grep 'You are on ovirt-node-ng-4.1'"
  end
end

%w(
  cockpit-ovirt-dashboard
  vdsm-gluster
).each do |package|
  package package.to_s do
    action :install
    not_if 'ls /usr/sbin/nodectl'
  end
end

if node['platform_version'] =~ /^8.*/
  package 'langpacks-en.noarch' do
    action :install
  end
end

service 'cockpit.socket' do
  action %i[enable start]
  not_if 'ls /usr/sbin/nodectl'
end

%w[
  mlocate
  aic94xx-firmware
  iwl100-firmware
  iwl1000-firmware
  iwl105-firmware
  iwl135-firmware
  iwl2000-firmware
  iwl2030-firmware
  iwl3160-firmware
  iwl3945-firmware
  iwl4965-firmware
  iwl5000-firmware
  iwl5150-firmware
  iwl6000-firmware
  iwl6000g2a-firmware
  iwl6000g2b-firmware
  iwl6050-firmware
  iwl7260-firmware
  iwl7265-firmware
].each do |package|
  package package.to_s do
    action :purge
    not_if 'ls /usr/sbin/nodectl'
  end
end

service 'nfs-server.service' do
  action %i[enable start]
end

service 'glusterd.service' do
  action %i[enable start]
end

service 'glustereventsd.service' do
  action %i[enable start]
  only_if 'systemctl list-unit-files | grep glustereventsd.service'
end

%w[
  cockpit
  glusterfs
  rpc-bind
  nfs
  mountd
].each do |svc|
  execute "firewall-cmd --add-service #{svc}" do
    not_if "firewall-cmd --query-service #{svc}"
    only_if 'systemctl is-active firewalld'
  end
  execute "firewall-cmd --add-service #{svc} --permanent" do
    not_if "firewall-cmd --query-service #{svc} --permanent"
    only_if 'systemctl is-active firewalld'
  end
end

unless node['ovirtgluster']['peers'].empty?
  file '/etc/hosts' do
    f = Chef::Util::FileEdit.new(path)
    node['ovirtgluster']['peers'].each do |p|
      search = '^' + p['peeraddress'].gsub(/\./, "\\.")
      shost = p['peername'].split('.')[0]
      f.insert_line_if_no_match(
        /#{search}/,
        "#{p['peeraddress']}    #{p['peername']}" + '    ' + "#{shost}\n"
      )
      content f.send(:editor).lines.join
    end
  end
end

execute 'mpathconf --enable' do
  not_if 'ls /etc/multipath.conf'
  only_if 'rpm -q device-mapper-multipath'
end

directory '/etc/multipath/conf.d/' do
  owner 'root'
  group 'root'
  mode '0755'
  only_if 'ls -d /etc/multipath'
end

cookbook_file '/etc/multipath/conf.d/freenas.conf' do
  source 'freenas.conf'
  owner 'root'
  group 'root'
  mode '0700'
  only_if 'ls -d /etc/multipath/conf.d'
  notifies :run, 'execute[multipath reconfigure]', :immediately
end

execute 'multipath reconfigure' do
  action :nothing
  only_if 'systemctl is-active multipathd.service'
end

gluster_common_params = {
  'cluster.data-self-heal-algorithm' => 'full',
  'cluster.eager-lock'               => 'enable',
  'cluster.choose-local'             => 'off',
  'performance.low-prio-threads'     => '32',
  'performance.strict-o-direct'      => 'on',
  'network.ping-timeout'             => '30',
  'network.remote-dio'               => 'disable',
  'performance.read-ahead'           => 'off',
  'performance.io-cache'             => 'off',
  'performance.quick-read'           => 'off',
  'storage.owner-uid'                => '36',
  'storage.owner-gid'                => '36',
  'cluster.server-quorum-type'       => 'server',
  'features.shard'                   => 'on',
  'cluster.shd-max-threads'          => '8',
  'cluster.shd-wait-qlength'         => '10000',
  'cluster.locking-scheme'           => 'granular',
  'cluster.granular-entry-heal'      => 'enable',
  'client.event-threads'             => '4',
  'server.event-threads'             => '4',
  'performance.client-io-threads'    => 'on',
  'performance.stat-prefetch'        => 'off' # Redhat BZ 1823423
}

if node['ovirtgluster']['peers'].length == 3 &&
   node['fqdn'] == node['ovirtgluster']['peers'].first['hostname']

  # probe peers
  node['ovirtgluster']['peers'][1..-1].each do |p|
    execute "gluster peer probe #{p['peername']}" do
      command "gluster peer probe #{p['peername']}"
      retries 3
      retry_delay 10
      not_if "egrep '^hostname.+=#{p['peername']}$' /var/lib/glusterd/peers/*"
    end
    execute "wait peer #{p['peername']} connected" do
      command "gluster peer status | sed -e '/Other names:/d' | grep -A 2 #{p['peername']} | grep 'Peer in Cluster (Connected)'"
      retries 10
      retry_delay 10
      not_if "gluster peer status | sed -e '/Other names:/d' | grep -A 2 #{p['peername']} | grep 'Peer in Cluster (Connected)'"
    end
  end

  # create volume
  unless node['ovirtgluster']['volumes'].empty?
    node['ovirtgluster']['volumes'].each do |v|
      volume_create_command = "gluster volume create #{v['name']} replica 3"
      node['ovirtgluster']['peers'].each do |p|
        volume_create_command += " #{p['peername']}:#{v['brick']}"
      end

      execute volume_create_command.to_s do
        not_if { ::File.exist?("/var/lib/glusterd/vols/#{v['name']}/info") }
      end

      gluster_common_params.each do |param, value|
        execute "gluster volume set #{v['name']} #{param} #{value}" do
          not_if "gluster volume get  #{v['name']} #{param} | awk '/#{param}/{print $2}' | grep ^#{value}$"
          only_if { ::File.exist?("/var/lib/glusterd/vols/#{v['name']}/info") }
        end
      end

      execute "gluster volume start #{v['name']}" do
        only_if { ::File.exist?("/var/lib/glusterd/vols/#{v['name']}/info") }
        not_if "gluster volume info #{v['name']} | awk '/^Status/{print $2;}' | grep Started"
      end
    end
  end
end

# Modify Self-Hosted Engine deploy playbooks for web proxy environment
unless node['ovirtgluster']['engine_fqdn'].empty?
  file 'modify engine_setup.yml' do
    path '/usr/share/ansible/roles/ovirt.engine-setup/tasks/engine_setup.yml'
    f = Chef::Util::FileEdit.new(File.file?(path) ? path : '/dev/null')
    f.search_file_replace_line(
      /when: ovirt_engine_setup_update_setup_packages or ovirt_engine_setup_perform_upgrade/,
      "    environment:\n      http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n      https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    when: ovirt_engine_setup_update_setup_packages or ovirt_engine_setup_perform_upgrade\n")
    f.search_file_replace_line(
      /when: not ovirt_engine_setup_offline\|bool/,
      "    environment:\n      http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n      https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    when: not ovirt_engine_setup_offline|bool\n")
    f.search_file_replace_line(
      /command: "engine-setup --accept-defaults --config-append={{ answer_file_path }} {{ offline }}"/,
      "    command: \"engine-setup --accept-defaults --config-append={{ answer_file_path }} {{ offline }}\"\n    environment:\n      http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n      https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n      no_proxy: #{node['ovirtgluster']['engine_fqdn']}\n")
    content f.send(:editor).lines.join
    only_if 'rpm -q ovirt-engine-appliance-4.4'
    not_if "grep #{node['http_proxy_host']}:#{node['http_proxy_port']} #{path}"
    only_if { ::File.exist?('/usr/share/ansible/roles/ovirt.engine-setup/tasks/engine_setup.yml') }
  end
end
if ::File.exist?('/usr/share/ansible/roles/ovirt.engine-setup/tasks')
  file 'modify hosted-engine-setup/tasks/install_packages.yml' do
    path '/usr/share/ansible/roles/ovirt.engine-setup/tasks/install_packages.yml'
    f = Chef::Util::FileEdit.new(File.file?(path) ? path : '/dev/null')
    f.search_file_replace_line(
      /when: ovirt_engine_setup_product_type \| lower == 'ovirt'/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  when: ovirt_engine_setup_product_type | lower == 'ovirt'\n")
    f.search_file_replace_line(
      /when: ovirt_engine_setup_product_type \| lower == 'rhv' and ansible_os_family == 'RedHat'/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  when: ovirt_engine_setup_product_type | lower == 'rhv' and ansible_os_family == 'RedHat'\n")
    f.search_file_replace_line(
      /when: ovirt_engine_setup_product_type \| lower == 'rhv' and rhevm_installed.results \| default\(\[\]\) | selectattr\(/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  when: ovirt_engine_setup_product_type | lower == 'rhv' and rhevm_installed.results | default([]) | selectattr(\n")

    f.search_file_replace_line(
      /with_items: "{{ ovirt_engine_setup_package_list }}"/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  with_items: \"{{ ovirt_engine_setup_package_list }}\"\n")

    content f.send(:editor).lines.join
    only_if 'rpm -q ovirt-engine-appliance-4.4'
    not_if "grep #{node['http_proxy_host']}:#{node['http_proxy_port']} #{path}"
  end
  file 'modify ovirt.hosted-engine-setup/tasks/install_packages.yml' do
    path '/usr/share/ansible/roles/ovirt.hosted-engine-setup/tasks/install_packages.yml'
    f = Chef::Util::FileEdit.new(File.file?(path) ? path : '/dev/null')
    f.search_file_replace_line(
      /register: task_result/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  register: task_result\n")
    content f.send(:editor).lines.join
    only_if 'rpm -q ovirt-engine-appliance-4.4'
    not_if "grep #{node['http_proxy_host']}:#{node['http_proxy_port']} #{path}"
  end
  file 'modify 03_hosted_engine_final_tasks.yml' do
    path '/usr/share/ansible/roles/ovirt.hosted-engine-setup/tasks/create_target_vm/03_hosted_engine_final_tasks.yml'
    f = Chef::Util::FileEdit.new(File.file?(path) ? path : '/dev/null')
    f.search_file_replace_line(
      /register: yum_result/,
      "    environment:\n      http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n      https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    register: yum_result\n")
    content f.send(:editor).lines.join
    only_if 'rpm -q ovirt-engine-appliance-4.4'
    not_if "grep #{node['http_proxy_host']}:#{node['http_proxy_port']} #{path}"
  end
  file 'modify install_appliance.yml' do
    path '/usr/share/ansible/roles/ovirt.hosted-engine-setup/tasks/install_appliance.yml'
    f = Chef::Util::FileEdit.new(File.file?(path) ? path : '/dev/null')
    f.search_file_replace_line(
      /register: task_result/,
      "  environment:\n    http_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n    https_proxy: http://#{node['http_proxy_host']}:#{node['http_proxy_port']}\n  register: task_result\n")
    content f.send(:editor).lines.join
    only_if 'rpm -q ovirt-engine-appliance-4.4'
    not_if "grep #{node['http_proxy_host']}:#{node['http_proxy_port']} #{path}"
  end
end
