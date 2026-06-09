require_relative "helpers"

module EpiDeploy

  include Helpers

  @use_tags_for_deploy = false
  @use_timestamped_deploy_tags = false
  @create_release_commit = false

  class << self

    attr_reader :use_tags_for_deploy
    attr_accessor :use_timestamped_deploy_tags
    attr_writer :create_release_commit

    def use_tags_for_deploy=(use_tags_for_deploy)
      print_warning "[Deprecation Warning] The use_tags_for_deploy option is now obsolete. Remove this from your configuration."
      @use_tags_for_deploy = use_tags_for_deploy
    end

    def create_release_commit?
      @create_release_commit
    end

  end

end
