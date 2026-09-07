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

    # returns nil if the capistrano task was not executed successfully, if the REVISION file was not found on the server,
    # or the REVISION file is empty.
    def extract_revision(stage)
      Tempfile.create do |f|
        return nil unless Kernel.system({ "REVISION_FILE" => f.path }, "bundle exec cap #{stage} deploy:download_revision")

        f.rewind
        revision = f.read.strip
        if revision.nil? || revision.empty?
          nil
        else
          revision
        end
      end
    end

  end
end
