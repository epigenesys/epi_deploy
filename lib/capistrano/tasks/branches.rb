if File.exist?('config/initializers/version.rb')
  require_relative 'config/initializers/version'
end

namespace :epi_deploy do
  task :set_branch do
    branch = if ENV['BRANCH']
      ENV['BRANCH']
    elsif Object.const_defined?('LATEST_RELEASE_TAG')
      LATEST_RELEASE_TAG
    end

    if branch.nil?
      raise 'Cannot determine commit to deploy as BRANCH environment variable is not set and LATEST_RELEASE_TAG constant in version.rb could not be found'
    end

    set :branch, branch
  end
end

before 'deploy:starting', 'epi_deploy:set_branch'
