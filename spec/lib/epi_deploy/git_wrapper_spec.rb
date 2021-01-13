require 'spec_helper'
require 'epi_deploy/git_wrapper'

describe EpiDeploy::GitWrapper do

  let(:mocked_git) { double(:git, current_branch: current_branch) }
  let(:current_branch) { 'main' }
  before(:each) do
    allow(subject).to receive(:git).and_return(mocked_git)
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

end
