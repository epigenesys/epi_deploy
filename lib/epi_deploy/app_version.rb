module EpiDeploy
  class AppVersion
    attr_accessor :version_file_path, :version, :latest_release_tag
    
    def initialize(current_dir = Dir.pwd)
      self.version_file_path = File.join(current_dir, 'config/initializers/version.rb')
    end

    def load
      if version_file_exists?
        File.open(version_file_path) do |f|
          contents = f.read
          self.version = extract_version_number(contents)
          self.latest_release_tag = extract_latest_release_tag(contents)
        end
      else
        self.version = 0
        self.latest_release_tag = ''
      end
    end

    def save!
      File.open version_file_path, 'w' do |f|
        f.write "APP_VERSION = '#{new_version}'\n"
        f.write "LATEST_RELEASE_TAG = '#{latest_release_tag}'\n"
      end
    end

    def bump!
      self.version += 1
    end

    def self.open(current_dir = Dir.pwd)
      app_version = self.new(current_dir)
      app_version.load
      app_version
    end

    private
      def version_file_exists?
        File.exist? version_file_path
      end
      
      def extract_version_number(contents)
        contents.match(/APP_VERSION = '(?<version>\d+).*'/)[:version].to_i
      end

      def extract_latest_release_tag(contents)
        if (match = contents.match(/LATEST_RELEASE_TAG = '(?<tag>[A-za-z0-9_-])+'/))
          match[:tag]
        else
          ''
        end
      end
    
  end
end