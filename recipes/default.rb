# recipes/default.rb
chef_gem 'excon' do
  compile_time false
  action :install
end

file '/tmp/status' do
  content lazy { http_status }
end

file '/tmp/httparty' do
  content httparty_status
end

file '/tmp/train_opts_ssh' do
  content train_opts_ssh
end

file '/tmp/rest_status' do
  content rest_status
end

chef_gem 'pony' do
    compile_time true
end

require 'pony'

file '/tmp/pony' do
  content pony_perms
end
