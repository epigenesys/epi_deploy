# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epi_deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "epi_deploy"
  gem.version       = EpiDeploy::VERSION
  gem.authors       = ["Anthony Nettleship", "Shuo Chen", "Chris Hunt"]
  gem.email         = ["a.nettleship@epigenesys.org.uk", "s.chen@epigenesys.org.uk", "c.hunt@epigenesys.org.uk"]
  gem.description   = "A gem to facilitate deployment across multiple git branches and evironments"
  gem.summary       = "eD"
  gem.homepage      = "http://www.epigenesys.co.uk"

  gem.files         = `git ls-files`.split($/) - ['config/deploy/production.rb']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('slop', '~> 3.6')
  gem.add_dependency('git',  '~> 1.2')
end
