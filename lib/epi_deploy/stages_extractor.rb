require 'set'
module EpiDeploy
  class StagesExtractor
    attr_accessor :multi_customer_stages, :all_stages
    def initialize
      self.multi_customer_stages  = Set.new
      self.all_stages = Set.new
      
      stage_config_files.each do |stage_config_file_name|
        matches = stage_config_file_name.match /(?<stage>[\w\-]+)(?:\.(?<customer>[\w\-]+))?\.rb/
  
        if matches[:customer]
          multi_customer_stages << matches[:stage]
          all_stages << "#{matches[:stage]}.#{matches[:customer]}"
        else
          all_stages << matches[:stage]
        end
      end
    end
    
    def multi_customer_stage?(stage)
      multi_customer_stages.include?(stage)
    end
    
    def valid_stage?(stage)
      all_stages.include?(stage) || multi_customer_stage?(stage)
    end
    
    private
      def stage_config_files
        @stage_config_files ||= Dir.chdir(File.join(Dir.pwd, 'config', 'deploy')) do
          Dir.glob("*.rb")
        end
      end
  end
end