require 'spec_helper'
require 'epi_deploy/config'
require 'epi_deploy/git_wrapper'

describe EpiDeploy::GitWrapper do

  let(:mocked_git) { double(:git, current_branch: current_branch, add_tag: true, push: true) }
  let(:commit) { 'caa2c06f96cb0e52cdc6059014bc69bd94573d7a592b8c380bca5348e1f6806e0e9ad9bd12d7a78b' }
  let(:current_branch) { 'main' }
  before(:each) do
    allow(subject).to receive(:git).and_return(mocked_git)
  end

  describe '#create_or_update_tag' do
    it 'adds a new tag for the stage to the commit' do
      expect(mocked_git).to receive(:push).with('origin', 'refs/tags/production', delete: true)
      expect(mocked_git).to receive(:add_tag).with('production', commit, any_args)
      expect(mocked_git).to receive(:push).with('origin', 'production')

      subject.create_or_update_tag 'production', commit
    end
  end

  describe '#create_or_update_branch' do
    it 'creates or moves the branch to the commit' do
      expect(Kernel).to receive(:system).with("git branch -f production #{commit}").and_return(true)
      expect(mocked_git).to receive(:push).with('origin', 'production', force: true, tags: false)

      subject.create_or_update_branch('production', commit)
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
        expect(subject).to_not be_on_primary_branch
      end
    end

  end

  describe '#current_branch' do
    specify 'It returns the current_branch from git' do
      expect(subject.current_branch).to eq mocked_git.current_branch
    end
  end

  describe '#delete_branches' do
    let(:branches) { ['production', 'demo'] }
    let(:local_branches) { [] }

    before do
      allow(subject).to receive(:local_branches).and_return(local_branches)
    end

    context 'if all the branches exist as local branches' do
      let(:production_branch) { double('production branch', delete: true) }
      let(:demo_branch) { double('demo branch', delete: true) }
      let(:local_branches) {
        [
          production_branch,
          demo_branch,
        ]
      }

      specify 'it deletes each branch from the remote' do
        allow(production_branch).to receive(:delete)
        allow(demo_branch).to receive(:delete)

        expect(subject).to receive(:run_custom_command).with("git push origin refs/heads/production refs/heads/demo --delete")

        subject.delete_branches(branches)
      end

      specify 'it deletes each branch locally' do
        allow(subject).to receive(:run_custom_command)
        expect(production_branch).to receive(:delete)
        expect(demo_branch).to receive(:delete)

        subject.delete_branches(branches)
      end
    end

    context 'if not all the branches exist as local branches' do
      let(:production_branch) { double('production branch') }
      let(:demo_branch) { double('demo branch') }
      let(:local_branches) { [production_branch ] }

      specify 'it deletes each branch from the remote' do
        allow(production_branch).to receive(:delete)

        expect(subject).to receive(:run_custom_command).with("git push origin refs/heads/production refs/heads/demo --delete")

        subject.delete_branches(branches)
      end

      specify 'it deletes only the branches that exist locally' do
        allow(subject).to receive(:run_custom_command)
        expect(production_branch).to receive(:delete)
        expect(demo_branch).to_not receive(:delete)

        subject.delete_branches(branches)
      end
    end
  end

  describe '#tags_for_object' do
    before do
      allow(subject).to receive(:`).with('git tag --points-at HEAD').and_return("test1\ntest2\n")
    end

    it 'returns a list of tags that point at a given object' do
      expect(subject.tags_for_object('HEAD')).to match_array ['test1', 'test2']
    end
  end

end
