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
    `git tag -a example_tag -m "For testing"`  # Create a pretend release
    `git push &> /dev/null`
    double_cmd('bundle')
    run_ed 'release --deploy production'
    expect(all_output).to include('Deploying to production...')
    assert_exit_status(0)
  end
  
end