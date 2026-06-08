# frozen_string_literal: true

require 'time'

require 'spec_helper'
require 'epi_deploy/stages_extractor'
require 'epi_deploy/release'

describe EpiDeploy::Release do
  subject { described_class.new(reference: "test", git_wrapper:, commit: "caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b", app_version:) }

  let(:version) { 41 }
  let(:git_wrapper) {
    instance_spy(
      EpiDeploy::GitWrapper,
      on_primary_branch?: true,
      pending_changes?: false,
      short_commit_hash: "abcdef12",
      current_branch: "main",
      most_recent_release_tag: "2026jun08-1215-4bc69b-v#{version}",
      release_tag_list: ["2026jun08-1215-4bc69b-v#{version}"],
    )
  }
  let(:app_version) { nil }
  let(:abort_exception) { RuntimeError.new "abort" }
  let(:expected_release_tag) { "#{Time.now.strftime("%Y%b%d-%H%M")}-#{git_wrapper.short_commit_hash}-v#{version + 1}".downcase }

  before { allow(Kernel).to receive(:abort).and_raise(abort_exception) }

  describe "#create!" do
    context "given EpiDeploy.create_release_commit option is configured to true" do
      let(:app_version) {
        instance_spy(
          EpiDeploy::AppVersion,
          version:,
          bump: version + 1,
          version_file_path: '',
          "latest_release_tag=": nil,
          save!: true
        )
      }

      before do
        allow(EpiDeploy).to receive(:create_release_commit?).and_return(true)
        allow(git_wrapper).to receive(:most_recent_commit).and_return(instance_double(Git::Object::Commit, message: 'Some non-release commit'))
      end

      context "if a release can be created" do
        it "returns true" do
          expect(subject.create!).to be true
        end

        it "performs a git pull to ensure code is the latest" do
          subject.create!

          expect(git_wrapper).to have_received(:pull)
        end

        it "bumps the version number" do
          subject.create!

          expect(app_version).to have_received(:bump)
        end

        it "commits the new version number" do
          subject.create!

          expect(git_wrapper).to have_received(:commit).with('Bumped to version 42 [skip ci]')
        end

        it 'sets the latest release tag in the app version to the newly-created tag' do
          subject.create!

          expect(app_version).to have_received(:latest_release_tag=).with expected_release_tag
        end

        it "creates a tag in the format YYYYmonDD-HHMM-CommitRef-version for the new commit" do
          subject.create!

          expect(git_wrapper).to have_received(:create_or_update_tag).with expected_release_tag, push: false
        end

        it "pushes the new version to primary branch to reduce the chance of version number collisions" do
          subject.create!

          expect(git_wrapper).to have_received(:push).with "main", tags: true
        end

        it "sets #tag to the newly-created tag" do
          subject.create!

          expect(subject.tag).to eq expected_release_tag
        end
      end

      context "if the primary branch is not checked out" do
        before { allow(git_wrapper).to receive(:on_primary_branch?).and_return(false) }

        specify "it aborts with an error message" do
          expect { subject.create! }.to raise_error abort_exception
          expect(Kernel).to have_received(:abort).with including "You can only create a release on the main or master branch. Please switch to main or master and try again."
        end
      end

      context "if there are pending changes" do
        before { allow(git_wrapper).to receive(:pending_changes?).and_return(true) }

        specify "it aborts with an error message" do
          expect { subject.create! }.to raise_error abort_exception
          expect(Kernel).to have_received(:abort).with including "You have pending changes, please commit or stash them and try again."
        end
      end

      context "if the most recent commit is a release commit" do
        before { allow(git_wrapper).to receive(:most_recent_commit).and_return(instance_double(Git::Object::Commit, message: 'Bumped to version 12 [skip ci]')) }

        specify "it returns false and does not create a release commit" do
          expect(subject.create!).to be false

          expect(git_wrapper).not_to have_received(:create_or_update_tag)
          expect(git_wrapper).not_to have_received(:commit)
        end
      end
    end

    context "given EpiDeploy.create_release_commit option is configured to false" do
      before do
        allow(EpiDeploy).to receive(:create_release_commit?).and_return(false)

        allow(git_wrapper).to receive(:git_object_for).with(git_wrapper.most_recent_release_tag).and_return(instance_double(Git::Object::Commit, sha: "3acd361a8177b06645822fe6df4ab486137709a0"))
        allow(git_wrapper).to receive(:most_recent_commit).and_return(instance_double(Git::Object::Commit, sha: "6815f6a9dfa318871fe3ab8dce53956dc59692b5"))
      end

      context "if a release can be created" do
        it "returns true" do
          expect(subject.create!).to be true
        end

        it "performs a git pull to ensure code is the latest" do
          subject.create!

          expect(git_wrapper).to have_received(:pull)
        end

        it "does not create a new commit" do
          subject.create!

          expect(git_wrapper).not_to have_received(:commit)
        end

        it "creates a tag in the format YYYYmonDD-HHMM-CommitRef-version on the current commit" do
          subject.create!

          expect(git_wrapper).to have_received(:create_or_update_tag).with expected_release_tag
        end

        it "sets #tag to the newly-created tag" do
          subject.create!

          expect(subject.tag).to eq expected_release_tag
        end
      end

      context "if the primary branch is not checked out" do
        before { allow(git_wrapper).to receive(:on_primary_branch?).and_return(false) }

        specify "it aborts with an error message" do
          expect { subject.create! }.to raise_error abort_exception
          expect(Kernel).to have_received(:abort).with including "You can only create a release on the main or master branch. Please switch to main or master and try again."
        end
      end

      context "if there are pending changes" do
        before { allow(git_wrapper).to receive(:pending_changes?).and_return(true) }

        specify "it aborts with an error message" do
          expect { subject.create! }.to raise_error abort_exception
          expect(Kernel).to have_received(:abort).with including "You have pending changes, please commit or stash them and try again."
        end
      end

      context "if the most recent release tag is on the most recent commit" do
        let(:latest_commit) { instance_double(Git::Object::Commit, sha: "e0b8e2a14ae2374c5a208ce238226c7dfb17040b") }

        before do
          allow(git_wrapper).to receive(:git_object_for).with(git_wrapper.most_recent_release_tag).and_return(latest_commit)
          allow(git_wrapper).to receive(:most_recent_commit).and_return(latest_commit)
        end

        specify "it returns false" do
          expect(subject.create!).to be false
        end

        specify "it does not create a new tag" do
          expect(git_wrapper).not_to have_received(:create_or_update_tag)
        end
      end

      context "if there are not any release tags" do
        let(:version) { 0 }

        before do
          allow(git_wrapper).to receive_messages(most_recent_release_tag: nil, release_tag_list: [])
        end

        specify "creates a new release tag with version 1" do
          subject.create!

          expect(git_wrapper).to have_received(:create_or_update_tag).with expected_release_tag
        end
      end

      context "when config/initializers/version.rb exists" do
        let(:app_version) { instance_double EpiDeploy::AppVersion, version_file_exists?: true }

        before do
          allow(app_version).to receive(:version=)
        end

        specify "it prints a message to prompt the file to be deleted" do
          allow($stdout).to receive(:puts)

          subject.create!

          expect($stdout).to have_received(:puts).with including "The file config/initializers/version.rb can be deleted as it is no longer needed"
        end
      end
    end
  end
end
