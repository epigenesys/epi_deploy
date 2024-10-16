require 'time'

require 'spec_helper'
require 'epi_deploy/stages_extractor'
require 'epi_deploy/release'

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
  def push(ref, **opts); end
  def pull; end
  def current_branch; 'main'; end
  def create_or_update_tag(stage, commit); end
  def delete_branches(branches); end
end

describe EpiDeploy::Release do

  let(:git_wrapper) { MockGit.new }
  let(:app_version) { double(bump: 42, version_file_path: '', :latest_release_tag= => nil, save!: true) }
  before do
    allow(subject).to receive_messages(reference: 'test', git_wrapper: git_wrapper, commit: 'caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b', app_version: app_version)
    allow(git_wrapper).to receive(:most_recent_commit).and_return(double('commit', message: 'Some non-release commit'))
  end

  describe "#create!" do
    describe "preconditions" do
      it "can only be done on the primary branch" do
        allow(git_wrapper).to receive_messages(on_primary_branch?: false)
        expect(subject).to receive(:print_failure_and_abort).with('You can only create a release on the main or master branch. Please switch to main or master and try again.')

        subject.create!
      end

      it "errors when pending changes exist" do
        allow(git_wrapper).to receive_messages(pending_changes?: true)
        expect(subject).to receive(:print_failure_and_abort).with('You have pending changes, please commit or stash them and try again.')

        subject.create!
      end
    end

    it "performs a git pull to ensure code is the latest" do
      allow(subject).to receive_messages(bump_version: nil)
      expect(git_wrapper).to receive(:pull)

      expect(subject.create!).to eq true
    end

    it "stops with a warning message when a git pull fails (eg. merge errors)" do
      allow(subject).to receive_messages(bump_version: nil)
      expect(git_wrapper).to receive(:pull)

      expect(subject.create!).to eq true
    end

    it "bumps the version number" do
      expect(app_version).to receive(:bump)

      expect(subject.create!).to eq true
    end

    it "commits the new version number" do
      allow(subject).to receive_messages bump_version: 42
      expect(git_wrapper).to receive(:commit).with('Bumped to version 42 [skip ci]')

      expect(subject.create!).to eq true
    end

    context 'given that the date and time is 2024-12-1 16:15:00' do
      before do
        now = Time.new 2014, 12, 1, 16, 15
        allow(Time).to receive_messages now: now
      end

      it 'sets the latest release tag in the version the newly-created tag' do
        expect(app_version).to receive(:latest_release_tag=).with('2014dec01-1615-abc1234-v42')

        expect(subject.create!).to eq true
      end

      it "creates a tag in the format YYYYmonDD-HHMM-CommitRef-version for the new commit" do
        allow(subject).to receive_messages bump_version: 42
        expect(git_wrapper).to receive(:create_or_update_tag).with('2014dec01-1615-abc1234-v42', push: false)

        expect(subject.create!).to eq true
      end
    end

    it "pushes the new version to primary branch to reduce the chance of version number collisions" do
      allow(subject).to receive_messages bump_version: 42
      expect(git_wrapper).to receive(:push).with('main', tags: true)

      expect(subject.create!).to eq true
    end

    it 'does not create a new release if the most recent commit is a release commit' do
      allow(git_wrapper).to receive(:most_recent_commit).and_return(double('commit', message: 'Bumped to version 12 [skip ci]'))
      expect(git_wrapper).to_not receive(:create_or_update_tag)

      expect(subject.create!).to eq false
    end
  end
end
