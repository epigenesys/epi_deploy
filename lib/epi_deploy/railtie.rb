require 'rails'
module EpiDeploy
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'epi_deploy/git.rb'
    end
  end
end
