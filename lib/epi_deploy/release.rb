module EpiDeploy
  class Release
  
    attr_accessor :version
    attr_accessor :tag
  
    def initialize(options)
    
    end
  
    def create!
      self.version = 'v13'
      self.tag     = '14DEC01-1618-da46vs-v13'
    end
  
  end
end