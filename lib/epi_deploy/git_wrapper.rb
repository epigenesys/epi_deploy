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

    def push(branch, **options)
      options = { force: false, tags: true }.merge(options)
      git.push 'origin', branch, **options
    end

    def add(files = nil)
      git.add files
    end

    def short_commit_hash
      git.log.first.sha[0..6]
    end

    def get_commit(git_reference)
      if git_reference == :latest
        print_failure_and_abort("There is no latest release. Create one, or specify a reference with --ref") if tag_list.empty?
        git_reference = tag_list.first
      end

      git.object(commit_hash_for(git_reference))
    end

    def create_or_update_tag(name, commit = nil, push: true)
      if push
        git.push('origin', "refs/tags/#{name}", delete: true)
      end

      git.add_tag(name, commit, annotate: true, f: true, message: name)

      if push
        git.push('origin', "refs/tags/#{name}")
      end
    end

    def create_or_update_branch(name, commit)
      force_create_branch(name, commit)
      self.push "refs/heads/#{name}", force: true, tags: false
    end

    def delete_branches(branches)
      remote_refs = branches.map { |branch| "refs/heads/#{branch}" }
      run_custom_command("git push origin #{remote_refs.join(' ')} --delete")
      local_branches(branches).each(&:delete)
    end

    def tag_list
      @tag_list ||= `git for-each-ref --sort=taggerdate --format '%(tag)' refs/tags`.gsub("'", '').split.reverse
    end

    def current_branch
      git.current_branch
    end

    def most_recent_commit
      git.log(1).first
    end

    def commit_hash_for(ref)
      `git rev-list -n1 #{ref}`.strip
    end

    private

    def git
      @git ||= ::Git.open(Dir.pwd)
    end

    def force_create_branch(name, commit)
      run_custom_command("git branch -f refs/heads/#{name} #{commit}")
    end

    def local_branches(branch_names = [])
      branches = git.branches.local.filter { |branch| branch_names.include? branch.name }
      branches || []
    end

    def run_custom_command(command)
      unless Kernel.system(command)
        raise ::Git::GitExecuteError.new("Failed to run command '#{command}'")
      end
    end
  end
end
