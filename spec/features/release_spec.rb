require 'spec_helper'
require 'support/aruba_helper'

describe "Release" do

  it "creates a new release" do
    setup_aruba_and_git
    run_ed "release"
    assert_exit_status(0)
    expect(all_output).to include("Release 1 created with tag #{Time.now.year}")
  end

  it "deploys the release if the flag is supplied" do
    setup_aruba_and_git
    run_simple 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_simple 'git push'
    double_cmd('bundle')
    run_ed 'release --deploy production'
    expect(all_output).to include('Deploying to production...')
    assert_exit_status(0)
  end

  it 'does not deploy a second environment if the first environment deployment fails' do
    setup_aruba_and_git
    run_simple 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_simple 'git push'
    double_cmd('bundle')
    run_ed 'release --deploy demo:production'
    expect(all_output).to include('Deploying to demo...')
    expect(all_output).to include('Deployment failed - please review output before deploying again')
    expect(all_output).to_not include('Deploying to production...')
    assert_exit_status(1)
  end

end
