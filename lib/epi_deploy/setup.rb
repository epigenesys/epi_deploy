module EpiDeploy
  class Setup
  
    def self.initial_setup_if_required
      app_version.initial_version_file_if_required
    end
    
    private
      def self.app_version(klass = EpiDeploy::AppVersion)
        @app_version ||= klass.new
      end
  end
end