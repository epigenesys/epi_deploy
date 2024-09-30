require 'spec_helper'
require 'epi_deploy/config'
require 'epi_deploy/git_wrapper'

describe EpiDeploy::GitWrapper do

  let(:mocked_git) { double(:git, current_branch: current_branch, add_tag: true, push: true) }
  let(:current_branch) { 'main' }
  before(:each) do
    allow(subject).to receive(:git).and_return(mocked_git)
  end

  describe '#update_tag_commit' do
    it 'adds a new tag for the stage to the commit' do
      allow(Kernel).to receive(:system).and_return(true)
      expect(mocked_git).to receive(:add_tag).with('production', 'main', any_args)

      subject.update_tag_commit 'production', 'main'
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
      let(:production_branch) { double('production branch') }
      let(:demo_branch) { double('demo branch') }
      let(:local_branches) {
        {
          'production' => production_branch,
          'demo' => demo_branch,
        }
      }

      specify 'it deletes each branch from the remote' do
        allow(production_branch).to receive(:delete)
        allow(demo_branch).to receive(:delete)

        expect(mocked_git).to receive(:push).with('origin', 'refs/heads/production', delete: true)
        expect(mocked_git).to receive(:push).with('origin', 'refs/heads/demo', delete: true)

        subject.delete_branches(*branches)
      end

      specify 'it deletes each branch locally' do
        expect(local_branches).to receive(:[]).with('production').and_call_original
        expect(local_branches).to receive(:[]).with('demo').and_call_original
        expect(production_branch).to receive(:delete)
        expect(demo_branch).to receive(:delete)

        subject.delete_branches(*branches)
      end
    end

    context 'if not all the branches exist as local branches' do
      let(:production_branch) { double('production branch') }
      let(:local_branches) {
        {
          'production' => production_branch,
        }
      }

      specify 'it deletes each branch from the remote' do
        allow(production_branch).to receive(:delete)

        expect(mocked_git).to receive(:push).with('origin', 'refs/heads/production', delete: true)
        expect(mocked_git).to receive(:push).with('origin', 'refs/heads/demo', delete: true)

        subject.delete_branches(*branches)
      end

      specify 'it deletes only the branches that exist locally' do
        expect(local_branches).to receive(:[]).with('production').and_call_original
        expect(local_branches).to_not receive(:[]).with('demo')
        expect(production_branch).to receive(:delete)

        subject.delete_branches(*branches)
      end
    end
  end

end
