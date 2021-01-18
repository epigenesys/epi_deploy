require 'spec_helper'
require 'support/aruba_helper'

describe "Release" do

  it "creates a new release" do
    setup_aruba_and_git
    run_command_and_stop 'bundle install --quiet'

    run_ed "release"

    expect(last_command_started).to have_exit_status(0)
    expect(all_output).to include("Release 1 created with tag #{Time.now.year}")
    expect(all_output).to_not include 'Capistrano deploying to production'
  end

  it "deploys the release if the flag is supplied" do
    setup_aruba_and_git
    run_command_and_stop 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_command_and_stop 'git push'
    run_command_and_stop 'bundle install --quiet'

    run_ed 'release --deploy production'

    expect(last_command_started).to have_exit_status(0)
    expect(all_output).to include('Deploying to production...')
    expect(all_output).to include 'Capistrano deploying to production'
  end

  it 'does not deploy a second environment if the first environment deployment fails' do
    setup_aruba_and_git
    run_command_and_stop 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_command_and_stop 'git push --tags'
    run_command_and_stop 'bundle install --quiet'

    run_ed 'release --deploy demo:production'

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include('Deploying to demo...')
    expect(all_output).to include('Deployment failed - please review output before deploying again')
    expect(all_output).to_not include('Deploying to production...')
    expect(all_output).to_not include 'Capistrano deploying to production'
  end

end
