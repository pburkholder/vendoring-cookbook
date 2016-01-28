chef_gem 'excon' do
  compile_time true
  action :install
end

file '/tmp/status' do
  content lazy { http_status }
end
