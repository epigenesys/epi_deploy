require_relative './helpers'
require 'git'

module EpiDeploy
  class Release

    include EpiDeploy::Helpers

    MONTHS = %w(jan feb mar apr may jun jul aug sep oct nov dec)

    attr_accessor :tag, :commit

    def create!
      return print_failure_and_abort 'You can only create a release on the master branch. Please switch to master and try again.' unless git_wrapper.on_master?
      return print_failure_and_abort 'You have pending changes, please commit or stash them and try again.'  if git_wrapper.pending_changes?

      begin
        git_wrapper.pull

        new_version = app_version.bump!
        git_wrapper.add(app_version.version_file_path)
        git_wrapper.commit "Bumped to version #{new_version} [skip ci]"

        self.tag = "#{date_and_time_for_tag}-#{git_wrapper.short_commit_hash}-v#{new_version}"
        git_wrapper.tag self.tag
        git_wrapper.push 'master'
      rescue ::Git::GitExecuteError => e
        print_failure_and_abort "A git error occurred: #{e.message}"
      end
    end

    def version
      app_version.version
    end

    def deploy!(environments)
      environments.each do |environment|
        begin
          git_wrapper.pull

          matches = environment.match(/\A(?<stage>[\w\-]+)(?:\.(?<customer>\w+))?\z/)

          # Force the branch to the commit we want to deploy
          git_wrapper.change_branch_commit(matches[:stage], commit)
          completed = run_cap_deploy_to(environment)
          if !completed
            print_failure_and_abort "Deployment failed - please review output before deploying again"
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
      return nil if commit.nil?
      release.commit = commit
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
        $stdout.puts "Deploying to #{environment}... "

        task_to_run = if stages_extractor.multi_customer_stage?(environment)
          "deploy_all"
        else
          "deploy"
        end

        Kernel.system "bundle exec cap #{environment} #{task_to_run}"
      end


      def stages_extractor
        @stages_extractor ||= StagesExtractor.new
      end

  end
end
