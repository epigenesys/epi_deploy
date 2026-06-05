require "git"

require_relative "helpers"
require_relative "git_wrapper"
require_relative "app_version"
require_relative "config"

module EpiDeploy
  class Release

    include EpiDeploy::Helpers

    MONTHS = %w[jan feb mar apr may jun jul aug sep oct nov dec]
    RELEASE_TAG_REGEX = /\A\d{4}[a-z]{3}\d{2}-\d{4}-[0-9a-f]+-v\d+\z/

    attr_accessor :reference
    attr_accessor :tag
    attr_accessor :commit
    attr_writer :git_wrapper
    attr_writer :app_version

    def initialize(reference: nil, tag: nil, commit: nil, git_wrapper: nil, app_version: nil)
      self.reference = reference
      self.tag = tag
      self.commit = commit
      self.git_wrapper = git_wrapper
      self.app_version = app_version
    end

    def create!
      if EpiDeploy.create_release_commit?
        create_with_commit!
      else
        create_without_commit!
      end
    end

    def version
      app_version.version
    end

    def release_tag_list
      git_wrapper.release_tag_list
    end

    def git_wrapper
      @git_wrapper ||= GitWrapper.new
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

    def create_with_commit!
      common_steps

      if git_wrapper.most_recent_commit.message.start_with? "Bumped to version"
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

    def create_without_commit!
      common_steps

      false if most_recent_commit_already_tagged?

    rescue ::Git::GitExecuteError => e
      print_failure_and_abort "A git error occurred: #{e.message}"
    end

    def common_steps
      prerelease_checks
      git_wrapper.pull
    end

    def prerelease_checks
      print_failure_and_abort "You can only create a release on the main or master branch. Please switch to main or master and try again." unless git_wrapper.on_primary_branch?
      print_failure_and_abort "You have pending changes, please commit or stash them and try again." if git_wrapper.pending_changes?
    end

    def app_version
      @app_version ||= AppVersion.open
    end

    def most_recent_commit_already_tagged?
      git_wrapper.git_object_for(git_wrapper.most_recent_release_tag) == git_wrapper.most_recent_commit
    end

    # Use Time.zone if we have it (i.e. Rails), otherwise use Time
    def date_and_time_for_tag(time_class = (Time.respond_to?(:zone) ? Time.zone : Time))
      time = time_class.now
      time.strftime "%Y#{MONTHS[time.month - 1]}%d-%H%M"
    end

    def get_commit(git_reference)
      if git_reference == :latest
        git_reference = git_wrapper.most_recent_release_tag
        print_failure_and_abort("There is no latest release. Create one, or specify a reference with --ref") if git_reference.nil?
      end

      git_wrapper.git_object_for(git_reference)
    end

  end
end
