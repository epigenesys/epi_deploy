require 'git'

module EpiDeploy
  class Git
      def on_master?
        git.current_branch == "master"
      end
      
      def pending_changes?
        git.status.changed.any?
      end
      
      def pull
        git.pull
      end
      
      def commit(message)
        git.commit_all message
      end
      
      def push(options = {force: false})
        Kernel.system "git push#{' -f' if options[:force]}"
      end
      
      def short_commit_hash
        git.log.first.sha[0..6]
      end
      
      def tag(tag_name)
        git.add_tag(tag_name)
      end
      
      def get_commit(git_reference)
        git_object = git.object(git_reference)
        return git_object if git_object.is_a?(::Git::Object::Commit)
        nil
      end
      
      def change_branch_commit(branch, commit)
        Kernel.system "git branch -f #{branch} #{commit}"
      end
      
      def tag_list(options = {limit: 5})
        `git tag`.split.reverse
      end
   
      private
        def git
          @git ||= ::Git.open(Dir.pwd)
        end
    
  end
end