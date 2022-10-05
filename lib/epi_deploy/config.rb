module EpiDeploy
  @@use_tags_for_deploy = false

  def self.use_tags_for_deploy
    @@use_tags_for_deploy
  end

  def self.use_tags_for_deploy=(use_tags_for_deploy)
    @@use_tags_for_deploy = use_tags_for_deploy
  end  
end