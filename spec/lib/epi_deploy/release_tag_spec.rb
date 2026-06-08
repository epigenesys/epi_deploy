require "spec_helper"

require "epi_deploy/release_tag"

RSpec.describe EpiDeploy::ReleaseTag do
  subject { described_class.new(timestamp:, commit:, version:) }

  let(:timestamp) { "2026jun20-1234" }
  let(:commit) { "123456ab" }
  let(:version) { "10" }

  describe ".parse" do
    it "returns an instance of ReleaseTag if the tag is valid" do
      tag = described_class.parse "2026jun20-1234-abcdef12-v10"

      expect(tag).not_to be_nil
      expect(tag).to have_attributes timestamp: Time.new(2026, 6, 20, 12, 34), commit: "abcdef12", version: 10
    end

    it "returns nil if the timestamp is not well-formatted" do
      tag = described_class.parse "2026jun201234-abcdef12-v10"

      expect(tag).to be_nil
    end

    it "returns nil if the timestamp is missing" do
      tag = described_class.parse "-abcdef12-v10"

      expect(tag).to be_nil
    end

    it "returns nil if the commit hash is invalid" do
      tag = described_class.parse "2026jun20-1234-sdfhsdf13-v10"

      expect(tag).to be_nil
    end

    it "returns nil if the commit hash is missing" do
      tag = described_class.parse "2026jun20-1234--v10"

      expect(tag).to be_nil
    end

    it "returns nil if the version is invalid" do
      tag = described_class.parse "2026jun20-1234-abcdef12-vsfn23ns"

      expect(tag).to be_nil
    end

    it "returns nil if the version is missing" do
      tag = described_class.parse "2026jun20-1234-abcdef12-v"

      expect(tag).to be_nil
    end

    it "returns nil if the string is empty" do
      tag = described_class.parse ""

      expect(tag).to be_nil
    end
  end

  describe "#increment" do
    it "returns a new instance with the current timestamp, the commit hash specified, and the version number incremented" do
      tag = subject.increment(commit: "ba654321")

      aggregate_failures do
        expect(tag).not_to be subject
        expect(tag.timestamp).to be_within(1).of Time.now
        expect(tag.commit).to eq "ba654321"
        expect(tag.version).to eq 11
      end
    end

    it "returns a new instance with the specified timestamp and commit hash, and the version number incremented if the timestamp is specified" do
      tag = subject.increment(commit: "ba654321", timestamp: "2026jun21-1234")

      aggregate_failures do
        expect(tag).not_to be subject
        expect(tag.timestamp).to eq Time.new(2026, 6, 21, 12, 34)
        expect(tag.commit).to eq "ba654321"
        expect(tag.version).to eq 11
      end
    end
  end

  describe "#to_s" do
    it "returns a representation of the tag for use with Git" do
      expect(subject.to_s).to eq "#{timestamp}-#{commit}-v#{version}"
    end
  end
end
