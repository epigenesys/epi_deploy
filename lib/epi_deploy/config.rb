require_relative "helpers"

module EpiDeploy

  extend Helpers

  @use_tags_for_deploy = false
  @use_timestamped_deploy_tags = false
  @create_release_commit = false

  class << self

    attr_reader :use_tags_for_deploy
    attr_accessor :use_timestamped_deploy_tags
    attr_reader :create_release_commit

    def use_tags_for_deploy=(use_tags_for_deploy)
      print_failure_and_abort <<~EOF.chomp
        The use_tags_for_deploy option is now obsolete. It has been superseded by use_timestamped_deploy_tags.
        See the section on branchless deployments in the README.
        https://github.com/epigenesys/epi_deploy/blob/master/README.md
      EOF
      @use_tags_for_deploy = use_tags_for_deploy
    end

    def create_release_commit=(value)
      if value
        print_warning <<~EOF.chomp
          [Deprecation Warning] The create_release_commit option should only be used
          if it is currently necessary for your workflow.

          Please migrate to commitless releases, as commitful releases will be removed
          in a future version. Instructions can be found in the README.
          https://github.com/epigenesys/epi_deploy/blob/master/README.md
        EOF
      end
      @create_release_commit = value
    end

    def create_release_commit?
      create_release_commit
    end

    def use_tags_for_deploy?
      use_tags_for_deploy
    end

    def use_timestamped_deploy_tags?
      use_timestamped_deploy_tags
    end

  end

end
