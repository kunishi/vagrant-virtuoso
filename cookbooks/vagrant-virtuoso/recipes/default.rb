#
# Cookbook Name:: vagrant-virtuoso
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

configure_options = '--prefix=/usr/local --with-layout=debian'
src_dir = '/usr/local/src/virtuoso-opensource'

include_recipe 'apt'
include_recipe 'build-essential'
include_recipe 'git'
include_recipe 'python'
include_recipe 'openjdk'

package 'gperf'
package 'libtool'
package 'libssl-dev' do
  case node[:platform]
  when 'redhat', 'centos'
    package_name 'openssl-dev'
  when 'ubuntu', 'debian'
    package_name 'libssl-dev'
  end
end
package 'libiodbc2'
package 'libiodbc2-dev'

git src_dir do
  repository 'git://github.com/openlink/virtuoso-opensource.git'
  action :sync
  notifies :run, 'execute[cleanup-virtuoso-source-dir]', :immediately
end

execute 'cleanup-virtuoso-source-dir' do
  cwd src_dir
  command 'make distclean'
  action :run
  only_if do File.exists?("#{src_dir}/Makefile") end
  notifies :run, 'execute[autogen-virtuoso]', :immediately
end

execute 'autogen-virtuoso' do
  cwd src_dir
  command './autogen.sh'
  action :run
  only_if do File.exists?("#{src_dir}/autogen.sh") end
  notifies :run, 'execute[configure-virtuoso]', :immediately
end

execute 'configure-virtuoso' do
  cwd src_dir
  command "./configure #{configure_options}"
  action :nothing
  only_if do File.exists?("#{src_dir}/configure") end
  notifies :run, 'execute[compile-virtuoso]', :immediately
end

execute 'compile-virtuoso' do
  cwd src_dir
  command 'make'
  action :nothing
  only_if do File.exists?("#{src_dir}/Makefile") end
  notifies :run, 'execute[install-virtuoso]', :immediately
end

execute 'install-virtuoso' do
  cwd src_dir
  command 'make install'
  only_if do File.exists?("#{src_dir}/binsrc/virtuoso/virtuoso-t") end
  action :nothing
  notifies :create, 'template[/etc/init.d/virtuoso-opensource-7]', :immediately
  notifies :create, 'template[/etc/default/virtuoso-opensource-7]', :immediately
  notifies :run, 'execute[register-virtuoso-service]', :immediately
  notifies :start, 'service[virtuoso-opensource-7]', :delayed
end

template '/etc/init.d/virtuoso-opensource-7' do
  source 'init.erb'
  mode "755"
  action :nothing
end

template '/etc/default/virtuoso-opensource-7' do
  source 'default.erb'
  mode '644'
  action :nothing
end

execute 'register-virtuoso-service' do
  command 'update-rc.d virtuoso-opensource-7 defaults'
  action :nothing
end

service 'virtuoso-opensource-7' do
  supports :start => true, :stop => true, :restart => true
end
