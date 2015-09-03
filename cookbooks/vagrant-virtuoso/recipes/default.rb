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

package 'gperf'
package 'libtool'
package 'Install OpenSSL dev' do
  case node[:platform]
  when 'redhat', 'centos'
    package_name 'openssl-dev'
  when 'ubuntu', 'debian'
    package_name 'libssl-dev'
  end
end
package 'libiodbc2'
package 'libiodbc2-dev'
package 'openjdk-7-jdk'
package 'python-dev'

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
  notifies :run, 'template[/etc/init.d/virtuoso-opensource-7]', :immediately
  notifies :run, 'template[/etc/default/virtuoso-opensource-7]', :immediately
  notifies :run, 'execute[run-virtuoso]', :delayed
end

template '/etc/init.d/virtuoso-opensource-7' do
  source 'init.rb'
  mode "755"
  action :nothing
end

template '/etc/default/virtuoso-opensource-7' do
  source 'default.rb'
  mode '644'
  action :nothing
end

execute 'run-virtuoso' do
  command 'update-rc.d virtuoso-opensource-7 defaults'
  service 'virtuoso-opensource-7' do
    action :restart
  end
end
