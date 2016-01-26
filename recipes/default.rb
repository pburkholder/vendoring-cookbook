#
# Cookbook Name:: excon-cookbook
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.


file '/tmp/status' do
  content http_status
end
