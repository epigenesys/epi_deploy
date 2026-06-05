require 'spec_helper'
require 'support/aruba_helper'

require "git"

describe "Release", :bundle, type: :aruba do
  let(:git) { Git.open(aruba.config.home_directory) }
  let(:short_commit_hash) { git.log[1].sha[0..6] }
  let(:expected_version) {}
  let(:expected_release_tag) { "#{Time.now.strftime("%Y%b%d-%H%M")}-#{short_commit_hash}-v#{expected_version}".downcase }

  context "given EpiDeploy.create_release_commit option is configured to true" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.create_release_commit = true
      RUBY
    end

    context "given no version.rb is found" do
      let(:expected_version) { 1 }

      it "creates a new release with version number 1 and does not deploy" do
        run_ed "release"

        expect(last_command_started).to have_exit_status(0)
        expect(all_output).to include("Release #{expected_version} created with tag #{expected_release_tag}")
        expect(all_output).not_to include 'Capistrano deploying to production'
      end
    end

    context "given an version.rb exists with APP_VERSION set to 5" do
      let(:expected_version) { 6 }

      before do
        write_file "config/initializers/version.rb", <<~RUBY
          APP_VERSION = '5'
        RUBY
      end

      it "creates a new release with version number and does not deploy" do
        run_ed "release"

        expect(last_command_started).to have_exit_status(0)
        expect(all_output).to include("Release #{expected_version} created with tag #{expected_release_tag}")
        expect(all_output).not_to include 'Capistrano deploying to production'
      end
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
