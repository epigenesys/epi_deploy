module EpiDeploy
  class AppVersion
    attr_reader :version_file_path
    
    def initialize(current_dir = Dir.pwd)
      @version_file_path = File.join(current_dir, 'config/initializers/version.rb')
    end
    
    def initial_version_file_if_required
      self.version = 0 unless version_file_exists?
    end
    
    def bump!
      self.version = version + 1
    end
    
    def version
      @version ||= extract_version_number
    end
    
    def version=(new_version)
      File.open version_file_path, 'w' do |f|
        f.write "APP_VERSION = '#{new_version}'"
      end
      @version = extract_version_number
    end
    
    private
      def version_file_exists?
        File.exist? version_file_path
      end
      
      def extract_version_number
        return 0 unless version_file_exists?
        File.read(version_file_path).match(/APP_VERSION = '(?<version>\d+).*'/)[:version].to_i
      end
    
  end
end