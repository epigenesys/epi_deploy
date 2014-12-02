require 'git'

module EpiDeploy
  class Git
    
      def initialize(current_directory)
        @git = ::Git.open(current_directory, log: Logger.new(STDOUT))
      end
    
      def on_master?
        git.current_branch == "master"
      end
      
      def pending_changes?
        git.status.changed.any?
      end
      
      def pull
        git.status.pull
      end
      
      def commit(message)
        git.commit_all message
      end
      
      def short_commit_hash
        git.log.first.sha[0..6]
      end
      
      def tag(tag_name)
        git.add_tag(tag_name)
      end
   
      private
        def git
          @git
        end
    
  end
end