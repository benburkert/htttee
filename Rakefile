begin
  require 'rspec/core/rake_task' rescue nil
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w[ -b -c -f documentation -r ./spec/spec_helper.rb ]
    t.pattern = 'spec/**/*_spec.rb'
  end

  task :default => :spec

rescue LoadError
end
