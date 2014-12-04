module EpiDeploy
  class Setup
  
    def self.initial_setup_if_required      
      create_version_file if File.exist? version_file_path
    end
    
    private
      def self.create_version_file
        File.open version_file_path, 'w' do |f|
          f.write "APP_VERSION = '0'"
        end
      end
      
      def self.version_file_path
        File.join(Dir.pwd, 'config/initializers/version.rb')
      end
  
  end
end