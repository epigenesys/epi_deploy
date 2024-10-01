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

    def create_or_update_tag(name, commit)
      git.push('origin', "refs/tags/#{name}", delete: true)
      git.add_tag(name, commit, annotate: true, f: true, message: name)
      git.push('origin', name)
    end

    def delete_branches(branches)
      branches.each do |branch|
        git.push('origin', "refs/heads/#{branch}", delete: true)
        if local_branches.has_key? branch
          branch_object = local_branches[branch]
          branch_object.delete
          local_branches.delete(branch)
        end
      end
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

    def local_branches
      @branches ||= git.branches.local.map do |branch|
        [branch.name, branch]
      end.compact.to_h
    end

  end
end
