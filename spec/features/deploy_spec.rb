require 'spec_helper'
require 'support/aruba_helper'

describe "Deploy", :bundle, type: :aruba do
  it "errors if environment doesn't exist" do
    run_ed 'deploy invalidenvironment'

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("Environment 'invalidenvironment' does not exist")
  end

  it "errors if no latest release" do
    run_ed 'deploy production'

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("There is no latest release. Create one, or specify a reference with --ref")
  end

  it "deploys latest release" do
    run_command_and_stop 'git tag -a 2026jun09-1610-c17fe6f-v1 -m "For testing"'  # Create a pretend release
    run_command_and_stop 'git push'

    run_ed 'deploy production'

    expect(all_output).to include('Deploying to production...')
    expect(last_command_started).to have_exit_status(0)
  end

  it "deploys the reference specified" do
    run_command_and_stop 'git tag -a feature-tag -m "For testing"'
    run_command_and_stop "git push"

    run_ed "deploy production -r feature-tag"
    expect(all_output).to include('Deploying to production...')
    expect(last_command_started).to have_exit_status(0)
  end

  context "given that EpiDeploy.use_timestamped_deploy_tags is configured to false" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.use_timestamped_deploy_tags = false
      RUBY
    end

    specify "it prints a deprecation warning that prompts me to switch to using tags" do
      run_command_and_stop 'git tag -a 2026jun09-1610-c17fe6f-v1 -m "For testing"'  # Create a pretend release
      run_command_and_stop 'git push'

      run_ed "deploy production"

      expect(all_output).to include "[Deprecation Warning] Branchless deployments will be the only option"
    end
  end

  context "given that EpiDeploy.use_tags_for_deploy is configured" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.use_tags_for_deploy = true
      RUBY
    end

    specify "it exits with an error" do
      run_ed "deploy production"

      expect(all_output).to include "The use_tags_for_deploy option is now obsolete. It has been superseded by use_timestamped_deploy_tags."
    end
  end
end
