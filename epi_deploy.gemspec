# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epi_deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "epi_deploy"
  gem.version       = EpiDeploy::VERSION
  gem.authors       = ["Anthony Nettleship", "Shuo Chen", "Chris Hunt", "James Gregory"]
  gem.email         = ["anthony.nettleship@epigenesys.org.uk", "shuo.chen@epigenesys.org.uk", "chris.hunt@epigenesys.org.uk", "james.gregory@epigenesys.org.uk"]
  gem.description   = "A gem to facilitate deployment across multiple git branches and evironments"
  gem.summary       = "eD"
  gem.homepage      = "https://www.epigenesys.org.uk"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('slop', '~> 3.6')
  gem.add_dependency('git',  '~> 1.5')
end
