require_relative './helpers'
require 'git'

module EpiDeploy
  class Release
  
    include EpiDeploy::Helpers
    
    MONTHS = %w(jan feb mar apr may jun jul aug sep oct nov dec)
  
    attr_accessor :tag, :commit
  
    def create!
      return fail 'You can only create a release on the master branch. Please switch to master and try again.' unless git.on_master?
      return fail 'You have pending changes, please commit or stash them and try again.'  if git.pending_changes?
      
      begin
        git.pull
      
        new_version = app_version.bump!
        git.add(app_version.version_file_path)
        git.commit "Bumped to version #{new_version}"
      
        self.tag = "#{date_and_time_for_tag}-#{git.short_commit_hash}-v#{new_version}"
        git.tag self.tag
        git.push
      rescue ::Git::GitExecuteError => e
        fail "A git error occurred: #{e.message}"
      end
    end
    
    def version
      app_version.version
    end
    
    def deploy!(environments)
      environments.each do |environment|
        begin
          git.pull
          # Force the branch to the commit we want to deploy
          git.change_branch_commit(environment, commit)
          git.push(force: true)
          Kernel.system "bundle exec cap #{environment} deploy:migrations"
        rescue ::Git::GitExecuteError => e
          fail "A git error occurred: #{e.message}"
        end
      end
    end
    
    def tag_list(options = nil)
      git.tag_list(options)
    end
    
    def git(klass = EpiDeploy::Git)
      @git ||= klass.new
    end
    
    def self.find(reference)
      release = self.new
      commit = release.git.get_commit(reference)
      return nil if commit.nil?
      release.commit = commit
      release
    end
  
    private
      def app_version(app_version_class = EpiDeploy::AppVersion)
        @app_version ||= app_version_class.new
      end
      
      # Use Time.zone if we have it (i.e. Rails), otherwise use Time
      def date_and_time_for_tag(time_class = (Time.respond_to?(:zone) ? Time.zone : Time))
        time = time_class.now
        time.strftime "%Y#{MONTHS[time.month - 1]}%d-%H%M"
      end

  end
end