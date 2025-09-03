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
        output = `bundle exec cap #{stage} deploy:revision`
        match = output.match(/^\s*.*?@.*?: (?<hash>[A-Za-z0-9]{40})/)

        if match && match[:hash]
          match[:hash]
        else
          nil
        end
      end
  end
end
