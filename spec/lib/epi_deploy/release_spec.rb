$: << File.expand_path('../../lib', __FILE__)
require 'epi_deploy/release'

class MockGit
  def initialize(options)
    @on_master       = options[:on_master].nil?       ? true  : options[:on_master]
    @pending_changes = options[:pending_changes].nil? ? false : options[:pending_changes]
  end
  
  def on_master?; @on_master; end
  def pending_changes?; @pending_changes; end
end

describe EpiDeploy::Release do
  
  describe "#create!" do
  
    describe "preconditions" do   
      it "can only be done on the master branch" do
        subject.git = MockGit.new on_master: false
        expect(subject).to receive(:print_failure).with('You can only create a release on the master branch. Please switch to master and try again.')
        subject.create!
      end
    
      it "errors when pending changes exist" do
        subject.git = MockGit.new pending_changes: true
        expect(subject).to receive(:print_failure).with('You have pending changes, please commit or stash them and try again.')
        subject.create!
      end
    end
    
    it "performs a git pull of master to ensure code is the latest and stops if it fails (e.g. due to conflicts)" do
      git = MockGit.new
      subject.git = git
      expect(git).to receive(:pull)
    end
    
    it "bumps the version number"
    
    it "commits the new version number"
    
    it "creates a tag in the format YYMonDD-HHMM-CommitRef-version for the new commit"
    
    it "pushes the new version to master to reduce the chance of version number collisions"
  
  end
end