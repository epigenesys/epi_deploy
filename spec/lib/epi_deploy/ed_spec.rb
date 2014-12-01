$: << File.expand_path('../../lib', __FILE__)
require 'epi_deploy/ed'

describe "eD" do
  
  describe "release" do
  
    describe "preconditions" do
      it "sets up the initial branches if they don't exist"
      
      it "creates a version.rb file if one does not exist"
      
      it "can only be done on the master branch"
    
      it "errors when pending changes exist"
    end
    
    it "performs a git pull of master to esnure code is latest"
    
    it "bumps the version number"
    
    it "commits the new version number"
    
    it "creates a tag in the format YYMonDD-HHMM-CommitRef-version for the new commit"
    
    it "pushes the new version to master to reduce the chance of version number collisions"
    
    describe "optional --deploy flag" do
      
      describe "required arguments" do
        it "errors if no deploy environment is provided"
        
        it "accepts one or more target environments"
        
        it "only accepts environments that exist"
      end
      
      it "moves each environment branch specified to point to the new release commit" 
      #git branch -f branch-name new-commit
      
      it "deploys to each environment specified"
      
      it "can be used via the shorthand -d"
    end
    
  end
  
  
  describe "deploy" do
    
    describe "preconditions" do
      it "sets up the initial branches if they don't exist"
    end
    
    describe "required arguments" do
      it "errors if no deploy environment is provided"
      
      it "accepts one or more target environments"
      
      it "only accepts environments that exist"
    end
    
    describe "optional --ref flag" do
      specify "if not supplied then the latest release is used"
      
      specify "if flag supplied with no argument then list of releases displayed with choice"
      
      it "can be supplied with a git reference"
      
      it "errors if the reference not exist"
      
      it "can be used via the shorthand -r"
    end
    
    it "deploys the specified release to each environment specified"
    
  end
  
  
  describe "--help" do
    it "gives an overview of the available commands"
  end
  
end