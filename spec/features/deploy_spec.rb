require 'spec_helper'
require 'support/aruba_helper'

describe "Deploy" do
  
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
    `git tag -a example_tag -m "For testing"`  # Create a pretend release
    `git push`
    expect(Kernel).to receive(:system).with("bundle exec cap production deploy:migrations")
    run_ed 'deploy production'
    assert_exit_status(0)
  end
  
end