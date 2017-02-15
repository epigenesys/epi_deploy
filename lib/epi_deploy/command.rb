Dir[File.join(File.dirname(__FILE__), '*.rb')].each { |f| require_relative f }

module EpiDeploy
  class Command
    
    include EpiDeploy::Helpers
    
    attr_accessor :options
    attr_accessor :args
    attr_accessor :release_class
    
    def initialize(options, args, release_class = EpiDeploy::Release)
      self.options = options
      self.args    = args
      self.release_class = release_class
    end

    def release(setup_class = EpiDeploy::Setup)
      setup_class.initial_setup_if_required
      
      release = self.release_class.new
      release.create!
      print_success "Release #{release.version} created with tag #{release.tag}"
      environments = self.options.to_hash[:deploy]
      self.deploy(environments) unless environments.nil?
    end
    
    def deploy(environments = self.args)
      raise Slop::InvalidArgumentError.new("No environments provided") unless environments.any?
      check_environments_are_valid(environments)
      release = self.release_class.find determine_release_reference(options)
      if release.nil?
        print_failure_and_abort "You did not enter a valid Git reference. Please try again."
      else
        if release.deploy!(environments)
          print_success "Deployment complete."
        else
          print_failure_and_abort "An error occurred."
        end
      end
    end
    
    
    private
      
      def prompt_for_a_release
        print_notice "Select a recent release (or just press enter for latest):"
        
        tag_list = {}
        self.release_class.new.tag_list.each_with_index do |release, i|
          number = i + 1
          tag_list[number.to_s] = release
          print_notice "#{number}: #{release}"
        end

        selected_release = nil
        while selected_release.nil? do
          selected_release = STDIN.gets[/\d/] rescue nil
          if selected_release.nil?
            return :latest
          else
            unless tag_list.key?(selected_release)
              print_failure_and_abort "Invalid selection '#{selected_release}'. Try again..."
              selected_release = nil
            end
          end
        end
        tag_list[selected_release]
      end

      def determine_release_reference(options)
        if options.ref?
          reference = options[:ref].to_s.strip
          reference = prompt_for_a_release if reference.empty?
          reference
        else
          :latest
        end
      end
      def check_environments_are_valid(environments)
        invalid_environments = environments.reject { |environment| stages_extractor.valid_stage?(environment) }
        raise Slop::InvalidArgumentError.new("Environment '#{invalid_environments.first}' does not exist") unless invalid_environments.empty?
      end
      
      def stages_extractor
        @stages_extractor ||= StagesExtractor.new
      end
    
  end
end