require 'spec_helper'
require 'support/aruba_helper'

describe "Deploy", type: :aruba do
  
  it "errors if environment doesn't exist" do
    setup_aruba_and_git
    run_ed 'deploy invalidenvironment'
    assert_exit_status(1)
    expect(all_output).to include("Environment 'invalidenvironment' does not exist")
  end
  
  it "errors if no latest release" do
    setup_aruba_and_git
    run_ed 'deploy production'
    assert_exit_status(1)
    expect(all_output).to include("There is no latest release. Create one, or specify a reference with --ref")
  end
  
  it "deploys latest release" do
    setup_aruba_and_git
    run_simple 'git tag -a example_tag -m "For testing"'  # Create a pretend release
    run_simple 'git push'
    double_cmd('bundle')
    run_ed 'deploy production -r example_tag'
    expect(all_output).to include('Deploying to production...')
    assert_exit_status(0)
  end
  
end