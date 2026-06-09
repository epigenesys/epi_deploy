require "git"

require_relative "helpers"
require_relative "git_wrapper"
require_relative "app_version"
require_relative "config"
require_relative "release_tag"

module EpiDeploy
  class Release

    include EpiDeploy::Helpers

    MONTHS = %w[jan feb mar apr may jun jul aug sep oct nov dec]

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
        print_warning "The file config/initializers/version.rb can be deleted as it is no longer needed" if app_version.version_file_exists?
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
        self.tag = ReleaseTag.new(commit: git_wrapper.short_commit_hash, version: new_version).to_s
        app_version.latest_release_tag = self.tag
        app_version.save!
        git_wrapper.reset
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

      result = false
      release_tag = nil

      if release_tag_list.empty?
        release_tag = ReleaseTag.new commit: git_wrapper.short_commit_hash, version: 1
      elsif most_recent_commit_already_tagged?
        self.app_version.version = most_recent_release_tag.version
      else
        release_tag = most_recent_release_tag.increment(commit: git_wrapper.short_commit_hash)
      end

      unless release_tag.nil?
        self.tag = "#{release_tag}"
        git_wrapper.create_or_update_tag(self.tag)
        self.app_version.version = release_tag.version

        result = true
      end

      result
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
      git_wrapper.git_object_for("#{most_recent_release_tag}").sha == git_wrapper.most_recent_commit.sha
    end

    def most_recent_release_tag
      @most_recent_release_tag ||= ReleaseTag.parse(git_wrapper.most_recent_release_tag)
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
