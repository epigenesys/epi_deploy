require 'git'
require_relative './helpers'

module EpiDeploy
  class GitWrapper
    include EpiDeploy::Helpers
    def on_primary_branch?
      ["main", "master"].include? current_branch 
    end

    def pending_changes?
      # replaced the git library with a system call
      # due to it iterating all project files when
      # doing a git status.
      !system("git diff --quiet --exit-code")
    end

    def pull
      git.pull('origin', current_branch)
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

    def update_stage_tag_or_branch(stage, commit)
      if EpiDeploy.use_tags_for_deploy
        update_tag_commit(stage, commit)
      else
        update_branch_commit(stage, commit)
      end
    end

    def update_branch_commit(stage, commit)
      Kernel.system "git branch -f #{stage} #{commit}"
      self.push stage, force: true, tags: true
    end

    def update_tag_commit(stage, commit)
      Kernel.system "git push origin :refs/tags/#{stage}"
      git.add_tag(stage, commit, annotate: true, f: true, message: stage)
      Kernel.system "git push origin --tags"
    end

    def tag_list
      @tag_list ||= `git for-each-ref --sort=taggerdate --format '%(tag)' refs/tags`.gsub("'", '').split.reverse
    end

    def current_branch
      git.current_branch
    end

    private

    def git
      @git ||= ::Git.open(Dir.pwd)
    end

  end
end
