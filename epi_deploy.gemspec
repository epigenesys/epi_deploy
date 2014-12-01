# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epi_deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "epi_deploy"
  gem.version       = EpiDeploy::VERSION
  gem.authors       = ["Anthony Nettleship", "Shuo Chen"]
  gem.email         = ["a.nettleship@epigenesys.co.uk", "s.chen@epigenesys.co.uk"]
  gem.description   = "A gem to help with the git branching model."
  gem.summary       = "EpiDeploy"
  gem.homepage      = "http://www.epigenesys.co.uk"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency('rake')
  gem.add_dependency('slop')
  gem.add_dependency('highline')
end
