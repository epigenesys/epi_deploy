module EpiDeploy
  class Release
  
    attr_accessor :version
    attr_accessor :tag
  
    def create!
      self.version = 'v13'
      self.tag     = '14DEC01-1618-da46vs-v13'
      true
    end
    
    def deploy!
      
    end
    
    def self.find(reference)
      new ''
    end
    
    def self.all(options)
      #`git tag`.split.sort_by { |ver| ver[/[\d.]+/].split('.').map(&:to_i) }.reverse
      %w(one two three)
    end
  
  end
end