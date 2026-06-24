require 'spec_helper'
require 'epi_deploy/config'
require 'epi_deploy/git_wrapper'

describe EpiDeploy::GitWrapper do
  subject { described_class.new git: }

  let(:git) { instance_spy Git::Base, current_branch:, add_tag: true, push: true }
  let(:commit) { 'caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b' }
  let(:current_branch) { 'main' }

  describe '#create_or_update_tag' do
    it 'adds a new tag for the stage to the commit' do
      subject.create_or_update_tag 'production', commit

      expect(git).to have_received(:push).with('origin', 'refs/tags/production', delete: true)
      expect(git).to have_received(:add_tag).with('production', commit, any_args)
      expect(git).to have_received(:push).with('origin', 'refs/tags/production')
    end
  end

  describe '#create_or_update_branch' do
    it 'creates or moves the branch to the commit' do
      allow(Kernel).to receive(:system).with("git branch -f production #{commit}").and_return(true)

      subject.create_or_update_branch('production', commit)

      expect(git).to have_received(:push).with('origin', 'refs/heads/production', force: true, tags: false)
    end
  end

  describe '#on_primary_branch?' do
    context 'When the current branch is main' do
      let(:current_branch) { 'main' }

      specify 'Then it returns true' do
        expect(subject).to be_on_primary_branch
      end
    end

    context 'When the current branch is master' do
      let(:current_branch) { 'master' }

      specify 'Then it returns true' do
        expect(subject).to be_on_primary_branch
      end
    end

    context 'When the current branch is anything else' do
      let(:current_branch) { 'feature/cool-feature-branch' }

      specify 'Then it returns false' do
        expect(subject).not_to be_on_primary_branch
      end
    end
  end

  describe '#current_branch' do
    specify 'It returns the current_branch from git' do
      expect(subject.current_branch).to eq git.current_branch
    end
  end

  describe '#delete_branches' do
    let(:branches) { instance_double Git::Branches, local: local_branches, remote: remote_branches }
    let(:production_branch) { instance_spy Git::Branch, delete: true, name: "production" }
    let(:demo_branch) { instance_spy Git::Branch, delete: true, name: "demo" }
    let(:staging_branch) { instance_spy Git::Branch, delete: true, name: "staging" }
    let(:local_branches) {
      [
        production_branch,
        demo_branch,
      ]
    }
    let(:remote_branches) {
      [
        production_branch,
        staging_branch,
      ]
    }

    before do
      allow(git).to receive(:branches).and_return(branches)
      allow(Kernel).to receive(:system).and_return(true)
    end

    it "only deletes branches locally if they exist" do
      subject.delete_branches %w[ production demo staging training ]

      aggregate_failures do
        expect(production_branch).to have_received :delete
        expect(demo_branch).to have_received :delete
        expect(staging_branch).not_to have_received :delete
      end
    end

    it "only deletes branches on the remote if they exist there" do
      subject.delete_branches %w[ production demo staging training ]

      expect(Kernel).to have_received(:system).with("git push origin refs/heads/production refs/heads/staging --delete")
    end

    it "does not nothing if the branches do not exist locally or remotely" do
      subject.delete_branches %w[ training ]

      expect(production_branch).not_to have_received :delete
      expect(demo_branch).not_to have_received :delete
      expect(staging_branch).not_to have_received :delete
      expect(Kernel).not_to have_received(:system).with including "git push origin"
    end
  end
end
