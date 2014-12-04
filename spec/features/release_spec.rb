require 'spec_helper'
require 'support/aruba_helper'

describe "Release" do
  
  it "creates a new release" do
    setup_aruba_and_git
    run_ed "release"
    assert_exit_status(0)
    expect(all_output).to include("Release 1 created with tag #{Time.now.year}")
  end
  
end