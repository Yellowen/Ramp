# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ramp/version', __FILE__)
require 'rake'

Gem::Specification.new do |gem|
  gem.authors       = ["Sameer Rahmani"]
  gem.email         = ["lxsameer@gnu.org"]
  gem.description   = %q{AMP protocol implementation in Ruby. For more information about AMP protocol take a look at http://amp-protocol.net/}
  gem.summary       = %q{AMP protocol implementation in Ruby}
  gem.homepage      = "http://ramp.yellowen.com/"
  gem.license	    = 'GPL-2'

  gem.has_rdoc	    = true
  gem.rdoc_options << '--main' << 'lib/ramp.rb' << '--exclude' << 'Rakefile' << '--exclude' << 'Gemfile'

  gem.files         = FileList['lib/**/*.rb', '.gitignore', 'ramp.gemspec', 'LICENSE', 'Gemfile', 'Rakefile'].to_a
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ramp"
  gem.require_paths = ["lib"]
  gem.version       = Ramp::VERSION

end
