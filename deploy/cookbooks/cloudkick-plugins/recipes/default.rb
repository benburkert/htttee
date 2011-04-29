directory "/usr/lib/cloudkick-agent/plugins" do
  owner "root"
  group "root"
  action :create
  recursive true
end

require_recipe "cloudkick-plugins::resque"
