require 'spec_helper'

describe "Release" do
  
  it "creates a new release" do
    @dirs = ["somewhere/else"]
    run_simple "ed release"
    assert_exit_status(0)
  end
  
end