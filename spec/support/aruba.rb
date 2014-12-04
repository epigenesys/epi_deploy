require 'git'
require 'aruba/api'
require 'aruba/reporting'

RSpec.configure do |config|
  config.include Aruba::Api

  config.before(:each) do
    @dirs = [File.join(File.dirname(__FILE__), '..', 'tmp', 'aruba')]
    restore_env
    clean_current_dir
    dir = @dirs.join
    `echo > #{dir}/README`
    g = Git.init(dir)
    g.add
    g.commit('initial commit')
  end
end