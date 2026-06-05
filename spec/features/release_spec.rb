require 'spec_helper'
require 'support/aruba_helper'

describe "Release", :bundle, type: :aruba do
  context "given EpiDeploy.create_release_commit option is configured to true" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.create_release_commit = true
      RUBY
    end

    it "creates a new release" do
      run_ed "release"

      expect(last_command_started).to have_exit_status(0)
      expect(all_output).to include("Release 1 created with tag #{Time.now.year}")
      expect(all_output).not_to include 'Capistrano deploying to production'
    end

    it "deploys the release if the flag is supplied" do
      run_ed 'release --deploy production'

      expect(last_command_started).to have_exit_status(0)
      expect(all_output).to include('Deploying to production...')
      expect(all_output).to include 'Capistrano deploying to production'
    end

    it 'does not deploy a second environment if the first environment deployment fails' do
      run_ed 'release --deploy demo:production'

      expect(last_command_started).to have_exit_status(1)
      expect(all_output).to include('Deploying to demo...')
      expect(all_output).to include('Deployment failed - please review output before deploying again')
      expect(all_output).not_to include('Deploying to production...')
      expect(all_output).not_to include 'Capistrano deploying to production'
    end
  end
end
