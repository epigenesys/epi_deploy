require_relative './message_helper.rb'
require_relative './release.rb'

module EpiDeploy
  class Command
    
    include EpiDeploy::MessageHelper
    
    attr_accessor :options
    attr_accessor :args
    
    def initialize(options, args)
      self.options = options
      self.args    = args
    end

    def release(options = {})
      setup_class = options[:setup_class] || EpiDeploy::Setup
      setup_class.initial_setup_if_required
      
      environments = options[:deploy]
      release = release_class.new
      if release.create!
        print_success "Release #{release.version} created with tag #{release.tag}"
        release.deploy! if options.deploy? && check_environments_are_valid(environments)
      else
        print_failure "Something went wrong."
      end
    end
    
    def deploy
      check_environments_are_valid(args)
      release = EpiDeploy::Release.find determine_release_reference(options)
      release.deploy!
    end
    
    
    private
      
      def prompt_for_a_release
        print_notice "Select a recent release (or just press enter for latest):"

        valid_releases = [:latest]
        EpiDeploy::Release.all(limit: 5).each_with_index do |release, i|
          number = i + 1
          valid_releases << number.to_s
          print_notice "#{number}: #{release}"
        end

        selected_release = nil
        while selected_release.nil? do
          selected_release = (STDIN.gets[/\d/] rescue nil) || :latest
          unless valid_releases.include?(selected_release)
            print_failure "Invalid selection '#{selected_release}'. Try again..."
            selected_release = nil
          end
        end
        selected_release
      end

      def determine_release_reference(options)
        options = options.to_hash
        if options.key? :ref
          reference = options[:ref].to_s.strip
          if reference.empty?
            prompt_for_a_release
          else
            reference
          end
        else
          :latest
        end
      end

      def valid_environments
        Dir.glob(
          File.join(File.dirname(__FILE__), '../../config/deploy/*.rb')
        ).map do |filepath| 
          File.basename filepath, ".rb"
        end
      end

      def check_environments_are_valid(environments)
        invalid_environments = environments - valid_environments
        raise Slop::InvalidArgumentError.new("Environment '#{invalid_environments.first}' does not exist") unless invalid_environments.empty?
      end
    
  end
end