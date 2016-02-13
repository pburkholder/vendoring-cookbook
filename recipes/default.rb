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
