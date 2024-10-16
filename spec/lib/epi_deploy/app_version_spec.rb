require 'fileutils'

require 'spec_helper'

require 'epi_deploy/app_version'

RSpec.describe EpiDeploy::AppVersion do
  let(:current_dir) { File.expand_path(File.join('../../../../tmp/test_directory'), __FILE__) }
  let(:initializers_dir) { File.join(current_dir, 'config/initializers') }
  let(:version_file_path) { File.join(initializers_dir, 'version.rb') }

  subject { described_class.new(current_dir) }

  before do
    FileUtils.mkdir_p(initializers_dir)
  end

  around do |example|
    begin
      example.run
    ensure
      if File.exist? version_file_path
        File.unlink(version_file_path)
      end
    end
  end

  describe '#load' do
    context 'given a version file does not exist' do
      it 'defaults the app version to 0' do
        subject.load

        expect(subject.version).to eq 0
      end

      it 'defaults to the latest release tag to an empty string' do
        subject.load

        expect(subject.latest_release_tag).to eq ''
      end
    end

    context 'given a version file does exist' do
      context 'and only a version is set in the file' do
        before do
          File.open(version_file_path, 'w') do |f|
            f.write("APP_VERSION = '3'")
          end
        end

        it 'loads the version number' do
          subject.load

          expect(subject.version).to eq 3
        end

        it 'defaults to the latest release tag to an empty string' do
          subject.load

          expect(subject.latest_release_tag).to eq ''
        end
      end

      context 'and both a version number and latest release tag is set in the file' do
        before do
          File.open(version_file_path, 'w') do |f|
            f.write("APP_VERSION = '3'\nLATEST_RELEASE_TAG = 'test_tag'")
          end
        end

        it 'loads the correct version number' do
          subject.load

          expect(subject.version).to eq 3
        end

        it 'loads the latest release tag' do
          subject.load

          expect(subject.latest_release_tag).to eq 'test_tag'
        end
      end
    end
  end

  describe '#save!' do
    subject do
      app_version = described_class.new(current_dir)
      app_version.version = 13
      app_version.latest_release_tag = 'another_test_tag'
      app_version
    end

    context 'given a version file does not exist' do
      it 'creates a new file with the correct contents' do
        subject.save!

        expect(File).to exist version_file_path
        File.open(version_file_path) do |f|
          contents = f.read
          expect(contents).to eq "APP_VERSION = '13'\nLATEST_RELEASE_TAG = 'another_test_tag'\n"
        end
      end
    end

    context 'given a version file does exist' do
      before do
        File.open(version_file_path, 'w') do |f|
          f.write("APP_VERSION = '3'\nLATEST_RELEASE_TAG = 'test_tag'")
        end
      end

      it 'creates a new file with the correct contents' do
        subject.save!

        File.open(version_file_path) do |f|
          contents = f.read
          expect(contents).to eq "APP_VERSION = '13'\nLATEST_RELEASE_TAG = 'another_test_tag'\n"
        end
      end
    end
  end

  describe '.open' do
    let(:app_version_double) { double('app version') }

    it 'creates a new app version class instance and loads the configuration from file' do
      expect(described_class).to receive(:new).and_return(app_version_double)
      expect(app_version_double).to receive(:load)

      described_class.open
    end
  end
end
