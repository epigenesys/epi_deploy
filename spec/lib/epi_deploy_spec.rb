require "spec_helper"

require "epi_deploy/config"

RSpec.describe EpiDeploy do
  before do
    allow(Kernel).to receive :warn
  end

  it "raises a warning when EpiDeploy.create_release_commit is set to true" do
    described_class.create_release_commit = true

    expect(Kernel).to have_received(:warn).with including "[Deprecation Warning] The create_release_commit option should only be used"
  end
end
