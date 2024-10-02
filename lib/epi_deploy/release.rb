require_relative './helpers'
require 'git'

module EpiDeploy
  class Release

    include EpiDeploy::Helpers

    MONTHS = %w(jan feb mar apr may jun jul aug sep oct nov dec)

    attr_accessor :reference, :tag, :commit

    def create!
      return print_failure_and_abort 'You can only create a release on the main or master branch. Please switch to main or master and try again.' unless git_wrapper.on_primary_branch?
      return print_failure_and_abort 'You have pending changes, please commit or stash them and try again.'  if git_wrapper.pending_changes?

      begin
        git_wrapper.pull

        new_version = app_version.bump!
        git_wrapper.add(app_version.version_file_path)
        git_wrapper.commit "Bumped to version #{new_version} [skip ci]"

        self.tag = "#{date_and_time_for_tag}-#{git_wrapper.short_commit_hash}-v#{new_version}"
        git_wrapper.tag self.tag
        git_wrapper.push git_wrapper.current_branch
      rescue ::Git::GitExecuteError => e
        print_failure_and_abort "A git error occurred: #{e.message}"
      end
    end

    def version
      app_version.version
    end

    def deploy!(stages_or_environments)
      begin
        git_wrapper.pull

        # Remove legacy environment branches in the local repo and remotely
        print_notice 'Removing any legacy deployment branches'
        git_wrapper.delete_branches(stages_extractor.environments)

        stages_or_environments.each do |stage_or_environment|
          stages_extractor.stages_for_stage_or_environment(stage_or_environment).each do |stage|
            tag_name = tag_name_for_stage(stage)
            
            completed = run_cap_deploy_to(stage)
            if completed
              git_wrapper.create_or_update_tag(tag_name, commit)
              print_success "Created deployment tag #{tag_name} on commit #{commit}"
            else
              print_failure_and_abort "Deployment failed - please review output before deploying again"
            end
          end
        rescue ::Git::GitExecuteError => e
          print_failure_and_abort "A git error occurred: #{e.message}"
        end
      end
    end

    def tag_list(options = nil)
      git_wrapper.tag_list(options)
    end

    def git_wrapper(klass = EpiDeploy::GitWrapper)
      @git_wrapper ||= klass.new
    end

    def self.find(reference)
      release = self.new
      commit = release.git_wrapper.get_commit(reference)
      print_failure_and_abort("Cannot find commit for reference '#{reference}'") if commit.nil?
      release.commit = commit
      release.reference = reference
      release
    end

    private

      def app_version(app_version_class = EpiDeploy::AppVersion)
        @app_version ||= app_version_class.new
      end

      # Use Time.zone if we have it (i.e. Rails), otherwise use Time
      def date_and_time_for_tag(time_class = (Time.respond_to?(:zone) ? Time.zone : Time))
        time = time_class.now
        time.strftime "%Y#{MONTHS[time.month - 1]}%d-%H%M"
      end

      def run_cap_deploy_to(environment)
        print_notice "Deploying to #{environment}... "

        task_to_run = if stages_extractor.multi_customer_stage?(environment)
          "deploy_all"
        else
          "deploy"
        end

        Kernel.system "bundle exec cap #{environment} #{task_to_run} target=#{reference}"
      end

      def stages_extractor
        @stages_extractor ||= StagesExtractor.new
      end

      def tag_name_for_stage(stage)
        timestamp = Time.now.strftime('%Y_%m_%d-%H_%M_%S')
        "#{stage}-#{timestamp}"
      end

  end
end
