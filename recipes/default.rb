# recipes/default.rb
chef_gem 'excon' do
  compile_time false
  action :install
end

file '/tmp/status' do
  content lazy { http_status }
end
