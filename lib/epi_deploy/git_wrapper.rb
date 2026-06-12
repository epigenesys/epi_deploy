require "git"
require_relative "./helpers"

module EpiDeploy
  class GitWrapper

    include EpiDeploy::Helpers
    attr_writer :git

    def initialize(git: nil)
      self.git = git
    end

    def on_primary_branch?
      ["main", "master"].include? current_branch
    end

    def pending_changes?
      !working_tree_clean? || !stage_clean?
    end

    # git library is not used here as #status iterates over all project files
    # which is not performant for large projects.
    def working_tree_clean?
      system "git diff --quiet --exit-code"
    end

    def stage_clean?
      system "git diff --cached --quiet --exit-code"
    end

    def pull
      git.pull("origin", current_branch)
    end

    def commit(message)
      git.commit message
    end

    def reset(...)
      git.reset(...)
    end

    def push(branch, **options)
      options = { force: false, tags: true }.merge(options)
      git.push "origin", branch, **options
    end

    def add(files = nil)
      git.add files
    end

    def short_commit_hash
      git.log.first.sha[0..6]
    end

    def create_or_update_tag(name, commit = nil, push: true)
      if push
        git.push("origin", "refs/tags/#{name}", delete: true)
      end

      git.add_tag(name, commit, annotate: true, f: true, message: name)

      if push
        git.push("origin", "refs/tags/#{name}")
      end
    end

    def create_or_update_branch(name, commit)
      force_create_branch(name, commit)
      self.push "refs/heads/#{name}", force: true, tags: false
    end

    def delete_branches(branches)
      # Delete remote branches
      remote_branches = filter_branches(git.branches.remote, branches)
      if remote_branches.any?
        remote_refs = remote_branches.map { |branch| "refs/heads/#{branch.name}" }
        run_custom_command("git push origin #{remote_refs.join(' ')} --delete")
      end

      # Delete local branches
      local_branches = filter_branches(git.branches.local, branches)
      local_branches.each(&:delete)
    end

    # Returns a list of all annotated tags sorted by the date which the tag was created, newest first
    def tag_list
      @tag_list ||= `git tag --list --sort=taggerdate --format='%(tag)'`.split.reverse
    end

    def release_tag_list
      @release_tag_list ||= tag_list.filter { |tag| tag.match? ReleaseTag::REGEXP }
    end

    def most_recent_release_tag
      release_tag_list.first
    end

    def current_branch
      git.current_branch
    end

    def most_recent_commit
      git.log(1).first
    end

    def git_object_for(ref)
      git.object(commit_hash_for(ref))
    end

    private

    def git
      @git ||= ::Git.open(Dir.pwd)
    end

    def force_create_branch(name, commit)
      run_custom_command("git branch -f #{name} #{commit}")
    end

    def filter_branches(branches, names = [])
      branches.filter { |branch| names.include? branch.name }
    end

    def run_custom_command(command)
      unless Kernel.system(command)
        raise ::Git::GitExecuteError.new("Failed to run command '#{command}'")
      end
    end

    def commit_hash_for(ref)
      `git rev-list -n1 #{ref}`.strip
    end

  end
end
