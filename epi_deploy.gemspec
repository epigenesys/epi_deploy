require_relative "lib/epi_deploy/version"

Gem::Specification.new do |gem|
  gem.name = "epi_deploy"
  gem.version = EpiDeploy::VERSION
  gem.authors = ["Anthony Nettleship", "Shuo Chen", "Chris Hunt", "James Gregory", "William Lee"]
  gem.email = ["anthony.nettleship@epigenesys.org.uk", "shuo.chen@epigenesys.org.uk", "chris.hunt@epigenesys.org.uk", "james.gregory@epigenesys.org.uk", "william.lee@epigenesys.org.uk"]
  gem.summary = "A gem to facilitate deployment across multiple Git branches and environments using Capistrano"
  gem.homepage = "https://github.com/epigenesys/epi_deploy"
  gem.license = "MIT"

  gem.files = Dir["bin/*", "lib/**", "LICENSE.txt", "README.md"]
  gem.executables   = Dir["bin/*"].map { |f| File.basename(f) }

  gem.required_ruby_version = ">= 3.0"

  gem.add_dependency "git", "~> 1.5"
  gem.add_dependency "slop", "~> 3.6"
  gem.add_dependency "bundler", ">= 2.5.23", "< 5"

  gem.add_development_dependency "rspec", "~> 3.1"
  gem.add_development_dependency "aruba", "~> 1.0.0"
  gem.add_development_dependency "byebug", "~> 11.0"
  gem.add_development_dependency "capistrano", "~> 3.6"
  gem.add_development_dependency "irb", "~> 1.0"
end
