require 'spec_helper'
require 'epi_deploy/stages_extractor'
require 'epi_deploy/command'
require 'slop'

class MockOptions
  
  def initialize(options = {})
    @options = options
  end
  def ref?
    true
  end
  def [](key); end
  def to_hash; @options; end
end

class MockRelease
  def create!; true; end
  def deploy!(environments); end
  def version; 5; end
  def tag; 'nice-taggy'; end
  def self.find(ref); new; end
  
  def tag_list
    []
  end
end

describe "Command" do
  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end
  let(:options) { MockOptions.new }
  let(:args)    { [] }
  
  describe "release" do
    subject { EpiDeploy::Command.new options, args, MockRelease }
    let(:setup_class) { double(initial_setup_if_required: true) }
      
    describe "preconditions" do
      it "sets up the initial bra nches if they don't exist" do
        expect(setup_class).to receive :initial_setup_if_required
        subject.release(setup_class)
      end
    end
    
    specify "the user is notified of success" do
      expect(subject).to receive_messages(print_success: "Release v5 created with tag nice-taggy")
      subject.release(setup_class)
    end
    
    describe "optional --deploy flag" do
      
      before do
        release = MockRelease.new
        allow(release).to receive_messages(create!: true)
        allow(MockRelease).to receive_messages(new: release)
      end
      
      it "deploys to the specified environments if options specified" do
        subject.options = MockOptions.new  deploy: %w(production)
        expect(subject).to receive(:deploy).with(%w(production))
        subject.release(setup_class)
      end
      
      it "does not deploy if option not specified" do
        expect(subject).to_not receive(:deploy)
        subject.release(setup_class)
      end
    end
  end
  
  describe "deploy" do
    before { allow(Kernel).to receive(:abort) }
    subject { EpiDeploy::Command.new options, args, MockRelease }
    
    around do |example|
      Dir.chdir(File.join(File.dirname(__FILE__), '../..', 'fixtures')) do
        example.call
      end
    end
    
    describe "required arguments" do
      it "errors if no deploy environment is provided" do
        expect{ subject.deploy }.to raise_error(Slop::InvalidArgumentError, "No environments provided")
      end
      
      it "accepts valid target environments" do
        subject.args = %w(production)
        allow(subject).to receive_messages(determine_release_reference: :latest)
        release = MockRelease.new
        allow(MockRelease).to receive_messages(find: release)
        expect(release).to receive(:deploy!).with(%w(production))
        subject.deploy
      end
      
      it "only accepts environments that exist" do
        subject.args = %w(cheese)
        expect{subject.deploy}.to raise_error(Slop::InvalidArgumentError, "Environment 'cheese' does not exist")
      end
    end
    
    describe "optional --ref flag" do
      subject { EpiDeploy::Command.new options, ['production'], MockRelease }
      let(:options) do
        options = Hash.new
        allow(options).to receive_messages(ref?: true)
        options
      end
      
      before do
        allow(subject).to receive_messages(valid_reference?: true)
      end
      
      specify "if not supplied then the latest release is used" do
        allow(options).to receive_messages(ref?: false)
        subject.options = options
        expect(subject.release_class).to receive(:find).with(:latest).and_return(MockRelease.new)
        subject.deploy
      end
      
      specify "if flag supplied with no argument then list of releases displayed with choice" do
        options[:ref] = nil
        subject.options = options
        expect(subject).to receive(:prompt_for_a_release)
        subject.deploy
      end
      
      it "can be supplied with a git reference" do
        options[:ref] = 'an_exisiting_ref'
        subject.options = options
        expect(subject.release_class).to receive(:find).with('an_exisiting_ref').and_return(MockRelease.new)
        subject.deploy
      end
      
      it "errors if the reference not exist" do
        options[:ref] = 'invalid_ref'
        subject.options = options
        allow(subject).to receive_messages(valid_reference?: false)
        expect(subject).to receive_messages(print_failure_and_abort: "You did not enter a valid Git reference. Please try again.")
        subject.deploy
      end
    end
  end
end