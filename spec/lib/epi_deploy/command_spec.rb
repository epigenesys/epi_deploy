$: << File.expand_path('../../lib', __FILE__)
require 'epi_deploy/command'

class MockOptions
  def deploy?; end
  def [](key); end
end

describe "Command" do
  
  describe "release" do
  
    describe "preconditions" do
      let(:options) { MockOptions.new }
      let(:args)    { '' }
      
      subject { EpiDeploy::Command.new options, args }
      
      it "sets up the initial branches if they don't exist" do
        setup_class = double
        expect(setup_class).to receive :initial_setup_if_required
        subject.release(setup_class)
        
        
#        it "creates a version.rb file if one does not exist"
      end
    end

    
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