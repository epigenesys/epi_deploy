require 'spec_helper'
require 'support/aruba_helper'

describe "Deploy", type: :aruba do

  it "errors if environment doesn't exist" do
    setup_aruba_and_git
    run_command_and_stop 'bundle install --quiet'

    run_ed 'deploy invalidenvironment'

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("Environment 'invalidenvironment' does not exist")
  end

  it "errors if no latest release" do
    setup_aruba_and_git
    run_command_and_stop 'bundle install --quiet'

    run_ed 'deploy production'

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("There is no latest release. Create one, or specify a reference with --ref")
  end

  it "deploys latest release" do
    setup_aruba_and_git
    run_command_and_stop 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_command_and_stop 'git push'
    run_command_and_stop 'bundle install --quiet'

    run_ed 'deploy production -r example_tag'

    expect(all_output).to include('Deploying to production...')
    expect(last_command_started).to have_exit_status(0)
  end

end
