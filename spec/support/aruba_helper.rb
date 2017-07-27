require 'git'
require 'aruba/api'
require 'aruba/reporting'
require 'aruba-doubles'

RSpec.configure do |config|
  config.include Aruba::Api
  config.include ArubaDoubles

  config.before do
    ArubaDoubles::Double.setup
  end

  config.after do
    ArubaDoubles::Double.teardown
  end
end

def local_repo
  File.expand_path('../../tmp/local_repo', __FILE__)
end

def setup_aruba_and_git
  @dirs = [local_repo]

  restore_env
  `rm -rf #{local_repo}`
  `mkdir -p #{local_repo}`

  `mkdir -p #{local_repo}/config/initializers`
  `mkdir -p #{local_repo}/config/deploy`

  `echo > #{local_repo}/config/initializers/.gitkeep`
  `cp -r #{File.expand_path('../../../config/deploy/*.rb', __FILE__)} #{local_repo}/config/deploy/`

  g = Git.init(local_repo)
  g.add
  g.commit('initial commit')

  # Set the remote repo to the local, works the same as an actual remote
  g.add_remote('origin', local_repo)

  `cd #{local_repo} && git push -u origin master &> /dev/null`
end
