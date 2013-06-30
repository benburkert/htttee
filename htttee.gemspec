Gem::Specification.new do |s|
  s.name        = "htttee"
  s.version     = '0.5.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Burkert"]
  s.email       = ["ben@benburkert.com"]
  s.homepage    = "http://github.com/benburkert/htttee"
  s.summary     = %q{Unix's tee as a service}
  s.description = %q{Stream any CLI output as an HTTP chunked response.}

  s.rubyforge_project = "htttee"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rack-client', '>= 0.4.2'
  s.add_dependency 'trollop'

  s.add_development_dependency 'sinatra'
  s.add_development_dependency 'thin'
  s.add_development_dependency 'em-redis'
  s.add_development_dependency 'yajl-ruby'
  s.add_development_dependency 'rack-mux'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
end
