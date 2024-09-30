require 'set'

module EpiDeploy
  class StagesExtractor
    STAGE_REGEX = /\A(?<stage>[\w\-]+)(?:\.(?<customer>\w+))?\z/
    DEPLOY_FILE_REGEX = /\A(?<stage>[\w\-]+)(?:\.(?<customer>[\w\-]+))?\.rb\z/

    attr_accessor :multi_customer_stages, :all_stages, :environments
    def initialize
      self.multi_customer_stages  = Set.new
      self.all_stages = Set.new
      self.environments = Set.new

      stage_config_files.each do |stage_config_file_name|
        matches = stage_config_file_name.match(DEPLOY_FILE_REGEX)
  
        if matches[:customer]
          multi_customer_stages << matches[:stage]
          all_stages << "#{matches[:stage]}.#{matches[:customer]}"
        else
          all_stages << matches[:stage]
        end

        environments << matches[:stage]
      end
    end
    
    def multi_customer_stage?(stage)
      multi_customer_stages.include?(stage)
    end
    
    def valid_stage?(stage)
      all_stages.include?(stage) || multi_customer_stage?(stage)
    end

    def self.match_with(environment)
      environment.match(STAGE_REGEX)
    end

    private
      def stage_config_files
        @stage_config_files ||= begin
          glob_pattern = File.join(Dir.pwd, 'config', 'deploy', '*.rb')
          Dir[glob_pattern].map { |path| File.basename(path) }
        end
      end
  end
end