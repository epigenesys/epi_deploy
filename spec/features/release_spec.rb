require 'spec_helper'

describe "Release" do
  
  it "creates a new release" do
    run_simple "#{File.join(File.dirname(__FILE__), '../../bin/ed')} release"
    assert_exit_status(0)
  end
  
end