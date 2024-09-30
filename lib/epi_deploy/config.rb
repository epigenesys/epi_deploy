module EpiDeploy
  @@use_tags_for_deploy = false

  def self.use_tags_for_deploy
    @@use_tags_for_deploy
  end

  def self.use_tags_for_deploy=(use_tags_for_deploy)
    warn '[Deprecation Warning] The use_tags_for_deploy option is now obsolete. Remove this from your configuration.'
    @@use_tags_for_deploy = use_tags_for_deploy
  end  
end