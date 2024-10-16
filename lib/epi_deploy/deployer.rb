require 'git'

require_relative 'helpers'
require_relative 'stages_extractor'

module EpiDeploy
  class Deployer
    include Helpers

    def initialize(release)
      @release = release
    end

    def deploy!(stages_or_environments)
      begin
        git_wrapper.pull

        if EpiDeploy.use_timestamped_deploy_tags
          deploy_with_timestamped_tags(stages_or_environments)
        else
          deploy_with_environment_branches(stages_or_environments)
        end
      rescue ::Git::GitExecuteError => e
        print_failure_and_abort "A git error occurred: #{e.message}"
      end
    end

    private

      def deploy_with_timestamped_tags(stages_or_environments)
        # Remove legacy environment branches in the local repo and remotely
        print_notice 'Removing any legacy deployment branches'
        git_wrapper.delete_branches(stages_extractor.environments)

        stages_or_environments.each do |stage_or_environment|
          stages_extractor.stages_for_stage_or_environment(stage_or_environment).each do |stage|
            tag_name = tag_name_for_stage(stage)

            completed = run_cap_deploy_to(stage)
            if completed
              git_wrapper.create_or_update_tag(tag_name, @release.commit)
              print_success "Created deployment tag #{tag_name} on commit #{@release.commit}"
            else
              print_failure_and_abort "Deployment failed - please review output before deploying again"
            end
          end
        end
      end

      def deploy_with_environment_branches(stages_or_environments)
        updated_branches = Set.new

        stages_or_environments.each do |stage_or_environment|
          begin
            git_wrapper.pull

            matches = StagesExtractor.match_with(stage_or_environment)
            # Force the tag/branch to the commit we want to deploy
            unless updated_branches.include? matches[:stage]
              git_wrapper.create_or_update_branch(matches[:stage], @release.commit)
              updated_branches << matches[:stage]
            end

            completed = run_cap_deploy_to(stage_or_environment)
            if !completed
              print_failure_and_abort "Deployment failed - please review output before deploying again"
            end
          rescue ::Git::GitExecuteError => e
            print_failure_and_abort "A git error occurred: #{e.message}"
          end
        end
      end

      def git_wrapper
        @git_wrapper ||= GitWrapper.new
      end

      def stages_extractor
        @stages_extractor ||= StagesExtractor.new
      end

      def tag_name_for_stage(stage)
        timestamp = Time.now.strftime('%Y_%m_%d-%H_%M_%S')
        "#{stage}-#{timestamp}"
      end

      def run_cap_deploy_to(environment)
        print_notice "Deploying to #{environment}... "

        task_to_run = if stages_extractor.multi_customer_stage?(environment)
          "deploy_all"
        else
          "deploy"
        end

        Kernel.system "BRANCH=#{@release.commit} bundle exec cap #{environment} #{task_to_run}"
      end
  end
end