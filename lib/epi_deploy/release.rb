require_relative './message_helper'
require_relative './git'

module EpiDeploy
  class Release
  
    include EpiDeploy::MessageHelper
    
    MONTHS = %w(jan feb mar apr may jun jul aug sep oct nov dec)
  
    attr_accessor :version_file_stream, :tag, :git
  
    def create!
      return print_failure 'You can only create a release on the master branch. Please switch to master and try again.' unless git.on_master?
      return print_failure 'You have pending changes, please commit or stash them and try again.'  if git.pending_changes?
      
      begin
        git.pull
      
        new_version = bump_version
        git.commit "Bumped to version #{new_version}"
      
        self.tag = "#{date_and_time_for_tag}-#{git.short_commit_hash}-v#{new_version}"
        git.tag self.tag
      
        git.push
      rescue Git::GitExecuteError => e
        print_failure "A git error occurred: #{e.message}"
      end
    end
    
    def deploy!(environments)
      environments.each do |environment|
        `bundle exec cap #{environment} deploy:migrations`
      end
    end
    
    def self.find(reference)
      new
    end
    
    def self.all(options)
      #`git tag`.split.sort_by { |ver| ver[/[\d.]+/].split('.').map(&:to_i) }.reverse
      %w(one two three)
    end
  
    private
      def bump_version
        new_version_number = self.version_file_stream.read.to_i + 1
        self.version_file_stream = StringIO.new(new_version_number.to_s)
        new_version_number
      end
      
      # Use Time.zone if we have it (i.e. Rails), otherwise use Time
      def date_and_time_for_tag(time_class = (Time.respond_to?(:zone) ? Time.zone : Time))
        time = time_class.now
        time.strftime "%Y#{MONTHS[time.month - 1]}%d-%H%M"
      end

  end
end