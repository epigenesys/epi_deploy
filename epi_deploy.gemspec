# frozen_string_literal: true

require_relative 'lib/epi_deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "epi_deploy"
  gem.version       = EpiDeploy::VERSION
  gem.authors       = ["Anthony Nettleship", "Shuo Chen", "Chris Hunt", "James Gregory", "William Lee"]
  gem.email         = ["anthony.nettleship@epigenesys.org.uk", "shuo.chen@epigenesys.org.uk", "chris.hunt@epigenesys.org.uk", "james.gregory@epigenesys.org.uk", "william.lee@epigenesys.org.uk"]
  gem.summary       = "A gem to facilitate deployment across multiple git branches and environments"
  gem.homepage      = "https://www.epigenesys.org.uk"

  gem.files         = Dir['README.md', 'LICENSE.txt', 'lib/**/*.rb', 'bin/*']
  gem.executables   = gem.files.grep(/^bin/).map{ |f| File.basename(f) }

  gem.required_ruby_version = '>= 2.7', '< 3.5'

  gem.add_dependency('slop', '~> 3.6')
  gem.add_dependency('git',  '~> 1.5')
end
