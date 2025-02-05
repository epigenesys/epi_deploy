require 'time'

require 'epi_deploy/deployer'

require 'spec_helper'

class MockGit
  def initialize(on_primary_branch: true, pending_changes: false)
    @on_primary_branch = on_primary_branch
    @pending_changes = pending_changes
  end
  def add(files); end
  def on_primary_branch?; @on_primary_branch; end
  def pending_changes?; @pending_changes; end
  def short_commit_hash; 'abc1234'; end
  def commit(msg); end
  def tag(name); end
  def push(opts = {}); end
  def pull; end
  def current_branch; 'main'; end
  def create_or_update_tag(name, commit); end
  def create_or_update_branch(name, commit); end
  def delete_branches(branches); end
end

def deployment_stage_with_timestamp(stage)
  satisfy do |tag_name|
    deploy_prefix, tag_stage, timestamp = tag_name.split('-', 3)
    deploy_prefix == 'deploy' && tag_stage == stage && (Time.now - Time.strptime(timestamp, '%Y_%m_%d-%H_%M_%S') <= 5)
  end
end

RSpec.describe EpiDeploy::Deployer do
  let(:release) { double('release') }
  let(:system_exit) { Exception.new('test exception') }
  let(:git_wrapper) { MockGit.new }
  subject { described_class.new(release) }

  before do
    allow(release).to receive_messages(reference: 'test', commit: 'caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b')
    allow(subject).to receive_messages(git_wrapper: git_wrapper)
  end

  describe "#deploy!" do
    before do
      allow_any_instance_of(EpiDeploy::Helpers).to receive_messages(print_notice: nil, print_success: nil)
      allow_any_instance_of(EpiDeploy::Helpers).to receive(:print_failure_and_abort) { raise system_exit }
    end

    around do |example|
      Dir.chdir(File.join(File.dirname(__FILE__), '../..', 'fixtures')) do
        example.run
      end
    end

    context 'given that timestamped deployment tags are enabled' do
      before do
        allow(EpiDeploy).to receive(:use_timestamped_deploy_tags).and_return(true)
      end

      it "runs the capistrano deploy command for each of the environments given" do
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap demo deploy").and_return(true)
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.epigenesys deploy").and_return(true)
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.genesys deploy").and_return(true)

        expect do
          subject.deploy! %w(demo production)
        end.to_not raise_error
      end

      context 'if deployment to all stages is successful' do
        it 'adds a tag for all deployment stages with the name of the stage and timestamp' do
          expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap demo deploy").and_return(true)
          expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.epigenesys deploy").and_return(true)
          expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.genesys deploy").and_return(true)

          expect(git_wrapper).to receive(:create_or_update_tag).with(deployment_stage_with_timestamp('demo'), release.commit)
          expect(git_wrapper).to receive(:create_or_update_tag).with(deployment_stage_with_timestamp('production.epigenesys'), release.commit)
          expect(git_wrapper).to receive(:create_or_update_tag).with(deployment_stage_with_timestamp('production.genesys'), release.commit)

          subject.deploy! ['production.epigenesys', 'production.genesys', 'demo']
        end
      end

      context 'if deployment to some stages is unsuccessful' do
        it 'only adds the tag to the deployment stages have succeeded' do
          expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.epigenesys deploy").and_return(true)
          expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.genesys deploy").and_return(false)
          expect(Kernel).to_not receive(:system).with("BRANCH=#{release.commit} bundle exec cap demo deploy")

          expect(git_wrapper).to receive(:create_or_update_tag).with(deployment_stage_with_timestamp('production.epigenesys'), release.commit)
          expect(git_wrapper).to_not receive(:create_or_update_tag).with(deployment_stage_with_timestamp('production.genesys'), release.commit)
          expect(git_wrapper).to_not receive(:create_or_update_tag).with(deployment_stage_with_timestamp('demo'), release.commit)

          expect { subject.deploy! ['production.epigenesys', 'production.genesys', 'demo'] }.to raise_error system_exit
        end
      end

      it 'deletes branches for all deployment environments' do
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.epigenesys deploy").and_return(true)
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production.genesys deploy").and_return(true)

        expect(git_wrapper).to receive(:delete_branches).with(a_collection_containing_exactly('production', 'demo'))

        subject.deploy! ['production']
      end
    end

    context 'given that timestamped deploy tags have not been enabled' do
      before do
        allow(EpiDeploy).to receive(:use_timestamped_deploy_tags).and_return(false)
      end

      it "runs the capistrano deploy task for single-customer environments" do
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap demo deploy").and_return(true)

        expect do
          subject.deploy! %w(demo)
        end.to_not raise_error
      end

      it 'runs the capistrano deploy_all task for multi-customer environments' do
        expect(Kernel).to receive(:system).with("BRANCH=#{release.commit} bundle exec cap production deploy_all").and_return(true)

        expect do
          subject.deploy! %w(production)
        end.to_not raise_error
      end

      it 'creates a branch for each deployment environment' do
        allow(Kernel).to receive(:system).and_return(true)

        expect(git_wrapper).to receive(:create_or_update_branch).with('demo', release.commit)
        expect(git_wrapper).to receive(:create_or_update_branch).with('production', release.commit).at_least(:once)

        expect do
          subject.deploy! ['production.epigenesys', 'production.genesys', 'demo']
        end.to_not raise_error
      end

      it 'creates a branch for a deployment stage each if it does not succeed but not for subsequent environments' do
        allow(Kernel).to receive(:system).and_return(false)

        expect(git_wrapper).to receive(:create_or_update_branch).with('demo', release.commit)
        expect(git_wrapper).to_not receive(:create_or_update_branch).with('production', any_args)

        expect do
          subject.deploy! ['demo', 'production']
        end.to raise_error system_exit
      end
    end
  end
end
