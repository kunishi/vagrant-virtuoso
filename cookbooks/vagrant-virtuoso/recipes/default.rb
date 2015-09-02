#
# Cookbook Name:: vagrant-virtuoso
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'apt'
include_recipe 'build-essential'
include_recipe 'git'

package 'gperf'
package 'Install OpenSSL dev' do
  case node[:platform]
  when 'redhat', 'centos'
    package_name 'openssl-dev'
  when 'ubuntu', 'debian'
    package_name 'libssl-dev'
  end
end
