module EpiDeploy
  @@use_tags_for_deploy = false

  def self.use_tags_for_deploy
    @@use_tags_for_deploy
  end

  def self.use_tags_for_deploy=(use_tags_for_deploy)
    warn 'This option is now deprecated and will no effect on deployment'
    warn 'Please remove this option from config/epi_deploy.rb as this may be removed in future releases' 
    @@use_tags_for_deploy = use_tags_for_deploy
  end  
end