require_relative './message_helper.rb'

module EpiDeploy
  class Release
  
    include EpiDeploy::MessageHelper
  
    attr_accessor :version
    attr_accessor :tag
    attr_accessor :git
  
    def create!
      return print_failure 'You can only create a release on the master branch. Please switch to master and try again.' unless git.on_master?
      return print_failure 'You have pending changes, please commit or stash them and try again.'  if git.pending_changes?
      
      self.version = 'v13'
      self.tag     = '14DEC01-1618-da46vs-v13'
      true
    end
    
    def deploy!
      
    end
    
    def self.find(reference)
      new
    end
    
    def self.all(options)
      #`git tag`.split.sort_by { |ver| ver[/[\d.]+/].split('.').map(&:to_i) }.reverse
      %w(one two three)
    end
  
  end
end