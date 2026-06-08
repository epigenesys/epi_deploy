require 'spec_helper'
require 'support/aruba_helper'

require "git"

describe "Release", :bundle, type: :aruba do
  let(:git) { Git.open(aruba.config.home_directory) }
  let(:short_commit_hash) {}
  let(:expected_version) {}
  let(:expected_release_tag) { "#{Time.now.strftime("%Y%b%d-%H%M")}-#{short_commit_hash}-v#{expected_version}".downcase }

  shared_examples "configured to not create release commit" do
    let(:short_commit_hash) { git.log.first.sha[0..6] }

    context "if there are no release tags" do
      let(:expected_version) { 1 }

      it "creates a new release tag with version 1 and the commit hash of the latest commit, and does not deploy" do
        run_ed "release"

        expect(last_command_started).to have_exit_status(0)
        expect(all_output).to include("Release #{expected_version} created with tag #{expected_release_tag}")
        expect(all_output).not_to include 'Capistrano deploying'
      end
    end

    context "if the most recent commit has a release tag" do
      let(:expected_version) { 1 }

      before { git.add_tag expected_release_tag, annotate: true, message: expected_release_tag }

      specify "it does not create a new release tag" do
        run_ed "release"

        expect(last_command_started).to have_exit_status(0)
        expect(all_output).to include("Release #{expected_version} has already been created on the most recent commit")
      end
    end

    context "if the file config/initializers/version.rb exists" do
      before do
        write_file "config/initializers/version.rb", <<~RUBY
          APP_VERSION = '5'
        RUBY
      end

      specify "it prints a message prompting me to delete the file" do
        run_ed "release"

        expect(all_output).to include "The file config/initializers/version.rb can be deleted as it is no longer needed"
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

  context "given EpiDeploy.create_release_commit option is configured to true" do
    let(:short_commit_hash) { git.log[1].sha[0..6] }

    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.create_release_commit = true
      RUBY
    end

    context "given no version.rb is found" do
      let(:expected_version) { 1 }

      it "creates a new release with version number 1 and the commit hash of the previous commit, and does not deploy" do
        run_ed "release"

        expect(last_command_started).to have_exit_status(0)
        expect(all_output).to include("Release #{expected_version} created with tag #{expected_release_tag}")
        expect(read "config/initializers/version.rb").to include "APP_VERSION = '1'"
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
        expect(read "config/initializers/version.rb").to include "APP_VERSION = '6'"
        expect(all_output).not_to include 'Capistrano deploying'
      end
    end

    context "if most recent commit is a release commit" do
      before do
        write_file "config/initializers/version.rb", <<~RUBY
          APP_VERSION = '5'
        RUBY
        git.add "config/initializers/version.rb"
        git.commit "Bumped to version 5 [skip ci]"
      end

      specify "it does not create a new release" do
        run_ed "release"

        expect(last_command_started).to have_exit_status 0
        expect(all_output).to include "Release 5 has already been created on the most recent commit"
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

  context "given EpiDeploy.create_release_commit option is not configured" do
    it_behaves_like "configured to not create release commit"
  end

  context "given EpiDeploy.create_release_commit option is set to false" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.create_release_commit = false
      RUBY
    end

    it_behaves_like "configured to not create release commit"
  end
end
