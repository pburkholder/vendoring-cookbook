#
# Cookbook Name:: excon-cookbook
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'excon'

def http_status
  response = Excon.get('http://google.com/index.html')
  response.status
end

file '/tmp/status' do
  content http_status
end
