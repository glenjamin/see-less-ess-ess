# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "see-less-ess-ess"
  gem.version       = '0.0.1'
  gem.authors       = ["Glen Mailer"]
  gem.email         = ["glenjamin@gmail.com"]
  gem.description   = %q{Remove unused CSS rules from a compass project}
  gem.summary       = %q{Remove unused CSS rules from a compass project}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
