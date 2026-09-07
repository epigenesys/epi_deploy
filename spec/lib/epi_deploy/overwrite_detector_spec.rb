require "spec_helper"

require "epi_deploy/overwrite_detector"
require "epi_deploy/release"

RSpec.describe EpiDeploy::OverwriteDetector do
  subject { described_class.new(release) }

  let(:stage) { "demo" }
  let(:deployed_revision) { "015b275d2ee4371456991ebfe9bb5f7fb6148aba" }
  let(:release) { instance_double(EpiDeploy::Release, reference: "features/example", commit: "ce2bba813f2e7debb232e81d1d0a8d971b05160c") }

  describe "#release_overwrites?" do
    context "if the REVISION file was found" do
      before do
        allow(Kernel)
          .to receive(:system)
          .with(hash_including("REVISION_FILE" => anything), "bundle exec cap #{stage} deploy:download_revision") do |env, _|
            File.write(env["REVISION_FILE"], deployed_revision)
          end
      end

      context "and the deployed revision is an ancestor of the release" do
        before do
          allow(release).to receive(:has_ancestor?).with(deployed_revision).and_return(true)
        end

        specify "it returns false" do
          expect(subject.release_overwrites?(stage)).to be false
        end
      end

      context "and the deployed revision is not an ancestor of the release" do
        before do
          allow(release).to receive(:has_ancestor?).with(deployed_revision).and_return(false)
        end

        specify "it returns false" do
          expect(subject.release_overwrites?(stage)).to be true
        end
      end
    end

    context "if the REVISION file was not fetched successfully" do
      before do
        allow(Kernel)
          .to receive(:system)
          .with(hash_including("REVISION_FILE" => anything), "bundle exec cap #{stage} deploy:download_revision")
          .and_return(false)
      end

      specify "it returns nil" do
        expect(subject.release_overwrites?(stage)).to be_nil
      end
    end

    context "if the REVISION file is empty" do
      before do
        allow(Kernel)
          .to receive(:system)
          .with(hash_including("REVISION_FILE" => anything), "bundle exec cap #{stage} deploy:download_revision") do |env, _|
            File.write(env["REVISION_FILE"], "")
          end
      end

      specify "it returns nil" do
        expect(subject.release_overwrites?(stage)).to be_nil
      end
    end
  end
end
