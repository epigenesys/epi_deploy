require 'git'
require_relative './helpers'

module EpiDeploy
  class GitWrapper
    include EpiDeploy::Helpers
    def on_master?
      git.current_branch == "master"
    end

    def pending_changes?
      git.status.changed.any?
    end

    def pull
      git.pull('origin', git.current_branch)
    end

    def commit(message)
      git.commit_all message
    end

    def push(branch, options = {force: false, tags: true})
      git.push 'origin', branch, options
    end

    def add(files = nil)
      git.add files
    end

    def short_commit_hash
      git.log.first.sha[0..6]
    end

    def tag(tag_name)
      git.add_tag(tag_name, annotate: true, message: tag_name)
    end

    def get_commit(git_reference)
      if git_reference == :latest
        print_failure_and_abort("There is no latest release. Create one, or specify a reference with --ref") if tag_list.empty?
        git_reference = tag_list.first
      end

      git_object_type = git.lib.object_type(git_reference)

      case git_object_type
        when 'tag'    then git.tag(git_reference)
        when 'commit' then git.object(git_reference)
        else nil
      end
    end

    def change_branch_commit(branch, commit)
      Kernel.system "git branch -f #{branch} #{commit}"
      self.push branch, force: true, tags: true
    end

    def tag_list(options = {limit: 5})
      @tag_list ||= `git for-each-ref --sort=taggerdate --format '%(tag)' refs/tags`.gsub("'", '').split.reverse
    end

    private
      def git
        @git ||= ::Git.open(Dir.pwd)
      end

  end
end
