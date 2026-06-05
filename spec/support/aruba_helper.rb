require 'git'
require 'aruba/rspec'

def setup_aruba_and_git
  local_repo = Aruba.config.home_directory
  copy "%/test_app/config", "%/test_app/Gemfile", "%/test_app/Capfile", "."

  g = Git.init(local_repo)
  g.config("push.autoSetupRemote", "true")
  g.config("user.name", "epiDeploy Test Account")
  g.config("user.email", "epi_deploy@example.test")
  g.add
  g.commit('initial commit')

  # Set the remote repo to the local, works the same as an actual remote
  g.add_remote('origin', local_repo)
  g.push("origin", "HEAD")
end

def run_ed(commands)
  run_command_and_stop "bundle exec epi_deploy #{commands}", fail_on_error: false
end

RSpec.configure do |config|
  config.include Aruba::Api

  config.around(type: :aruba) do |example|
    setup_aruba_and_git
    if example.metadata[:bundle]
      run_command_and_stop 'bundle install --quiet'
    end

    example.run
  end
end
