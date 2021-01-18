require 'git'
require 'aruba/api'

RSpec.configure do |config|
  config.include Aruba::Api
end

def local_repo
  File.expand_path("../../../#{Aruba.config.working_directory}", __FILE__)
end

def setup_aruba_and_git
  @dirs = [local_repo]

  setup_aruba
  `rm -rf #{local_repo}`
  `mkdir -p #{local_repo}`
  `cp #{File.expand_path('../../../Gemfile*', __FILE__)} #{local_repo}`

  `mkdir -p #{local_repo}/config/initializers`
  `mkdir -p #{local_repo}/config/deploy`

  `echo > #{local_repo}/config/initializers/.gitkeep`
  `cp -r #{File.expand_path('../../../config/deploy/*.rb', __FILE__)} #{local_repo}/config/deploy/`

  g = Git.init(local_repo)
  g.add
  g.commit('initial commit')

  # Set the remote repo to the local, works the same as an actual remote
  g.add_remote('origin', local_repo)

  `cd #{local_repo} && git push --quiet -u origin $(git symbolic-ref --short HEAD) &> /dev/null`
end
