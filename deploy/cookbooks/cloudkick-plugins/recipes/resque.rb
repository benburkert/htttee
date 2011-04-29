execute 'restart-cloudkick-agent' do
  action :nothing

  command 'pkill cloudkick-agent'
end

template "/usr/lib/cloudkick-agent/plugins/resque" do
  mode "0755"
  source "resque.sh.erb"
  variables(
    :dir       => "/data/#{node.engineyard.environment.apps.first.name}/current",
    :script    => "script/cloudkick-resque",
    :rack_env  => node.engineyard.environment.framework_env,
    :redis_uri => "#{node.engineyard.environment.db_host}:6379"
  )

  notifies :run, resources(:execute => 'restart-cloudkick-agent')
end
