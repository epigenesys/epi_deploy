require 'time'

require 'spec_helper'
require 'epi_deploy/stages_extractor'
require 'epi_deploy/release'

describe EpiDeploy::Release do
  subject { described_class.new(reference: "test", git_wrapper: git_wrapper, commit: "caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b", app_version: app_version) }

  let(:git_wrapper) { instance_spy(EpiDeploy::GitWrapper, on_primary_branch?: true, pending_changes?: false, short_commit_hash: "abcdef12", current_branch: "main") }
  let(:app_version) { instance_spy(EpiDeploy::AppVersion, version: 42, bump: 42, version_file_path: '', "latest_release_tag=": nil, save!: true) }

  before do
    allow(git_wrapper).to receive(:most_recent_commit).and_return(instance_double(Git::Object::Commit, message: 'Some non-release commit'))
  end

  describe "#create!" do
    context "given EpiDeploy.create_release_commit option is configured to true" do
      before { allow(EpiDeploy).to receive(:create_release_commit?).and_return(true) }

      describe "preconditions" do
        it "can only be done on the primary branch" do
          allow(git_wrapper).to receive(:on_primary_branch?).and_return(false)
          allow(Kernel).to receive(:abort)

          subject.create!

          expect(Kernel).to have_received(:abort).with including "You can only create a release on the main or master branch. Please switch to main or master and try again."
        end

        it "errors when pending changes exist" do
          allow(git_wrapper).to receive(:pending_changes?).and_return(true)
          allow(Kernel).to receive(:abort)

          subject.create!

          expect(Kernel).to have_received(:abort).with including "You have pending changes, please commit or stash them and try again."
        end
      end

      it "performs a git pull to ensure code is the latest" do
        expect(subject.create!).to be true

        expect(git_wrapper).to have_received(:pull)
      end

      it "bumps the version number" do
        expect(subject.create!).to be true

        expect(app_version).to have_received(:bump)
      end

      it "commits the new version number" do
        expect(subject.create!).to be true

        expect(git_wrapper).to have_received(:commit).with('Bumped to version 42 [skip ci]')
      end

      context 'given that the date and time is 2024-12-1 16:15:00' do
        let(:expected_release_tag) { "#{Time.now.strftime("%Y%b%d-%H%M")}-#{git_wrapper.short_commit_hash}-v#{app_version.version}".downcase }

        before do
          allow(EpiDeploy).to receive(:create_release_commit?).and_return(true)
        end

        it 'sets the latest release tag in the version the newly-created tag' do
          expect(subject.create!).to be true

          expect(app_version).to have_received(:latest_release_tag=).with expected_release_tag
        end

        it "creates a tag in the format YYYYmonDD-HHMM-CommitRef-version for the new commit" do
          expect(subject.create!).to be true

          expect(git_wrapper).to have_received(:create_or_update_tag).with expected_release_tag, push: false
        end
      end

      it "pushes the new version to primary branch to reduce the chance of version number collisions" do
        expect(subject.create!).to be true

        expect(git_wrapper).to have_received(:push).with "main", tags: true
      end

      it 'does not create a new release if the most recent commit is a release commit' do
        allow(git_wrapper).to receive(:most_recent_commit).and_return(instance_double(Git::Object::Commit, message: 'Bumped to version 12 [skip ci]'))

        expect(subject.create!).to be false

        expect(git_wrapper).not_to have_received(:create_or_update_tag)
      end
    end
  end
end
