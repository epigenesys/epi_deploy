$: << File.expand_path('../../lib', __FILE__)
require 'epi_deploy/release'

class MockGit
  def initialize(options = {})
    @on_master       = options[:on_master].nil?       ? true  : options[:on_master]
    @pending_changes = options[:pending_changes].nil? ? false : options[:pending_changes]
  end
  def on_master?; @on_master; end
  def pending_changes?; @pending_changes; end
  def short_commit_hash; 'abc1234'; end
  def commit(msg); end
  def tag(name); end
  def push(opts = {}); end
  def pull; end
  def change_branch_commit(branch, commit); end
end

describe EpiDeploy::Release do

  let(:git) { MockGit.new }
  before do
    subject.git = git
  end
  
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
    
    it "performs a git pull of master to ensure code is the latest" do
      allow(subject).to receive_messages(bump_version: nil)
      expect(git).to receive(:pull)
      subject.create!
    end
    
    it "stops with a warning message when a git pull fails (eg. merge errors)" do
      allow(subject).to receive_messages(bump_version: nil)
      expect(git).to receive(:pull)
      subject.create!
    end
    
    it "bumps the version number" do
      subject.version_file_stream = StringIO.new("APP_VERSION = '41'")
      subject.create!
      expect(subject.version_file_stream.read).to eq("APP_VERSION = '42'")
    end
    
    it "commits the new version number" do
      allow(subject).to receive_messages bump_version: 42
      expect(git).to receive(:commit).with('Bumped to version 42')
      subject.create!
    end
    
    it "creates a tag in the format YYYYmonDD-HHMM-CommitRef-version for the new commit" do
      allow(subject).to receive_messages bump_version: 42
      now = Time.new 2014, 12, 1, 16, 15
      allow(Time).to receive_messages now: now 
      expect(git).to receive(:tag).with('2014dec01-1615-abc1234-v42')
      subject.create!
    end
    
    it "pushes the new version to master to reduce the chance of version number collisions" do
      allow(subject).to receive_messages bump_version: 42
      expect(git).to receive(:push)
      subject.create!
    end
  end
  
  describe "#deploy!" do
    
    it "runs the capistrano deploy command for each of the environments given" do
      expect(Kernel).to receive(:system).with('bundle exec cap a deploy:migrations')
      expect(Kernel).to receive(:system).with('bundle exec cap b deploy:migrations')
      expect(Kernel).to receive(:system).with('bundle exec cap c deploy:migrations')
      subject.deploy! %w(a b c)
    end
    
  end
  
end