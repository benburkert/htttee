execute "restart god" do
  command <<-SRC
    if pgrep god; then
      god quit
    fi
  SRC
  action :nothing
end

gem_package "god" do
  version "0.11.0"
  action :install
  notifies :run, resources(:execute => "restart god")
end

directory "/etc/god" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

template "/etc/god/config" do
  owner "root"
  group "root"
  mode 0644
  source "config.erb"
end

execute "telinit q" do
  command "telinit q"
  action :nothing
end

template "/tmp/god-inittab" do
  owner "root"
  group "root"
  mode 0644
  source "god-inittab.erb"
end

execute "make init work with god" do
  command "cat /tmp/god-inittab >>/etc/inittab"
  not_if "grep '# god config' /etc/inittab"
  notifies :run, resources(:execute => "telinit q")
end

file "/tmp/god-inittab" do
  action :delete
end
