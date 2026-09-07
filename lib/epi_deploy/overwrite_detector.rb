module EpiDeploy
  class OverwriteDetector

    attr_reader :release

    def initialize(release)
      @release = release
    end

    def release_overwrites?(stage)
      @overwrites ||= {}
      @overwrites[stage] ||= calculate_overwrite(stage)
    end

    private

    def calculate_overwrite(stage)
      revision = extract_revision(stage)
      return nil if revision.nil?

      !release.has_ancestor?(revision)
    end

    # returns nil if the regex does not match for two reasons:
    #  1. the command failed to execute
    #  2. the REVISION file was not found on the remote
    def extract_revision(stage)
      Tempfile.create do |f|
        return nil unless Kernel.system({ "REVISION_FILE" => f.path }, "bundle exec cap #{stage} deploy:download_revision")
        f.rewind
        f.read.strip
      end
    end

  end
end
