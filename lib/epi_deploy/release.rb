require_relative './helpers'
require 'git'

module EpiDeploy
  class Release

    include EpiDeploy::Helpers

    MONTHS = %w(jan feb mar apr may jun jul aug sep oct nov dec)

    attr_accessor :reference, :tag, :commit

    def create!
      return print_failure_and_abort 'You can only create a release on the main or master branch. Please switch to main or master and try again.' unless git_wrapper.on_primary_branch?
      return print_failure_and_abort 'You have pending changes, please commit or stash them and try again.'  if git_wrapper.pending_changes?

      begin
        git_wrapper.pull

        if git_wrapper.most_recent_commit.message.start_with? 'Bumped to version'
          false
        else
          new_version = app_version.bump
          self.tag = "#{date_and_time_for_tag}-#{git_wrapper.short_commit_hash}-v#{new_version}"
          app_version.latest_release_tag = self.tag
          app_version.save!
          git_wrapper.add(app_version.version_file_path)
          git_wrapper.commit "Bumped to version #{new_version} [skip ci]"

          git_wrapper.create_or_update_tag(self.tag, push: false)
          git_wrapper.push(git_wrapper.current_branch, tags: true)

          true
        end
      rescue ::Git::GitExecuteError => e
        print_failure_and_abort "A git error occurred: #{e.message}"
      end
    end

    def version
      app_version.version
    end

    def release_tags_list
      git_wrapper.tag_list.filter do |tag|
        tag.match?(/\A\d{4}[a-z]{3}\d{2}-\d{4}-[0-9a-f]+-v\d+\z/)
      end
    end

    def git_wrapper(klass = EpiDeploy::GitWrapper)
      @git_wrapper ||= klass.new
    end

    def self.find(reference)
      release = self.new
      commit = release.send(:get_commit, reference)
      print_failure_and_abort("Cannot find commit for reference '#{reference}'") if commit.nil?
      release.commit = commit
      release.reference = reference
      release
    end

    private

      def app_version(app_version_class = EpiDeploy::AppVersion)
        @app_version ||= app_version_class.open
      end

      # Use Time.zone if we have it (i.e. Rails), otherwise use Time
      def date_and_time_for_tag(time_class = (Time.respond_to?(:zone) ? Time.zone : Time))
        time = time_class.now
        time.strftime "%Y#{MONTHS[time.month - 1]}%d-%H%M"
      end

      def get_commit(git_reference)
        if git_reference == :latest
          print_failure_and_abort("There is no latest release. Create one, or specify a reference with --ref") if self.release_tags_list.empty?
          git_reference = release_tags_list.first
        end
  
        git_wrapper.git_object_for(git_reference)
      end

  end
end
