require 'set'

module EpiDeploy
  class StagesExtractor
    STAGE_REGEX = /\A(?<stage>[\w\-]+)(?:\.(?<customer>\w+))?\z/
    DEPLOY_FILE_REGEX = /\A(?<stage>[\w\-]+)(?:\.(?<customer>[\w\-]+))?\.rb\z/

    attr_accessor :multi_customer_stages, :all_stages
    def initialize
      self.multi_customer_stages  = Set.new
      @environment_to_stages = {}

      stage_config_files.each do |stage_config_file_name|
        matches = stage_config_file_name.match(DEPLOY_FILE_REGEX)

        if matches[:customer]
          multi_customer_stages << matches[:stage]
        end

        @environment_to_stages[matches[:stage]] ||= Set.new
        @environment_to_stages[matches[:stage]] << matches[1..2].compact.join('.')
      end

      # Remove stage with same name as environment if it's a multi-customer stage
      # e.g. removes production from the set of production stages
      # if production has production.epigenesys and production.genesys
      multi_customer_stages.each do |environment|
        if @environment_to_stages.has_key? environment
          @environment_to_stages[environment].delete(environment)
        end
      end

      self.all_stages = Set.new(@environment_to_stages.values.map(&:to_a).flatten)
    end
    
    def multi_customer_stage?(stage)
      multi_customer_stages.include?(stage)
    end
    
    def valid_stage?(stage)
      all_stages.include?(stage) || multi_customer_stage?(stage)
    end

    def stages_for_environment(environment)
      @environment_to_stages[environment] || Set.new
    end

    def environments
      @environment_to_stages.keys
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