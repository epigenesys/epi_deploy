module EpiDeploy
  @use_tags_for_deploy = false
  @use_timestamped_deploy_tags = false

  class << self
    attr_reader :use_tags_for_deploy
    attr_accessor :use_timestamped_deploy_tags

    def use_tags_for_deploy=(use_tags_for_deploy)
      warn '[Deprecation Warning] The use_tags_for_deploy option is now obsolete. Remove this from your configuration.'
      @use_tags_for_deploy = use_tags_for_deploy
    end
  end
end