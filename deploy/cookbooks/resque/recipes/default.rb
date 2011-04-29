if node.engineyard.name == "resque" || node.engineyard.role == "solo"
  require_recipe "god"

  node[:applications].each do |app, data|
    template "/etc/god/resque_#{app}.rb" do
      owner "root"
      group "root"
      mode 0644
      source "resque.rb.erb"
      variables(
        :app                  => app,
        :app_root             => "/data/#{app}/current",
        :resque_workers_count => 4
      )
      notifies :run, resources(:execute => "restart god")
    end

    template "/etc/god/resque_scheduler_#{app}.rb" do
      owner "root"
      group "root"
      mode 0644
      source "resque_scheduler.rb.erb"
      variables(
        :app                  => app,
        :app_root             => "/data/#{app}/current",
        :resque_workers_count => 1
      )
      notifies :run, resources(:execute => "restart god")
    end
  end
end

if %w[solo app app_master util].include? node[:instance_role]
  node[:applications].each do |app, data|
    template "/data/#{app}/shared/config/resque.yml" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0655
      source "resque.yml.erb"
      variables(
        :framework_env => node.engineyard.environment.framework_env,
        :redis_host    => node.engineyard.environment.db_host,
        :redis_port    => 6379
      )
    end
  end
end
