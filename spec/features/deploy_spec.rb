require "spec_helper"
require "support/aruba_helper"

describe "Deploy", :bundle, type: :aruba do
  let(:git) { Git.open(aruba.config.home_directory) }

  it "errors if environment doesn't exist" do
    run_ed "deploy invalidenvironment"

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("Environment 'invalidenvironment' does not exist")
  end

  it "errors if no latest release" do
    run_ed "deploy production"

    expect(last_command_started).to have_exit_status(1)
    expect(all_output).to include("There is no latest release. Create one, or specify a reference with --ref")
  end

  it "deploys latest release" do
    git.add_tag "2026jun09-1610-c17fe6f-v1", nil, annotate: true, f: true, message: "For testing"
    git.push

    run_ed "deploy production"

    expect(all_output).to include("Deploying to production...")
    expect(last_command_started).to have_exit_status(0)
  end

  it "deploys the reference specified" do
    git.add_tag "feature-tag", nil, annotate: true, f: true, message: "For testing"
    git.push

    run_ed "deploy production -r feature-tag"
    expect(all_output).to include("Deploying to production...")
    expect(last_command_started).to have_exit_status(0)
  end

  context "given that EpiDeploy.use_timestamped_deploy_tags is configured to true" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.use_timestamped_deploy_tags = true
      RUBY
    end

    specify "it adds a tag to the latest release if no reference is specified" do
      git.add_tag "2026jun09-1610-c17fe6f-v1", nil, annotate: true, f: true, message: "For testing"
      git.push
      git.commit("test message", allow_empty: true)

      run_ed "deploy production"

      deploy_tag = git.object "#{git.tags.filter { |tag| tag.name.start_with? "deploy-production" }.first.name}^{}"
      release_tag = git.object "2026jun09-1610-c17fe6f-v1^{}"

      expect(deploy_tag.sha).to eq release_tag.sha
    end

    specify "it adds a tag to the specified reference if is specified" do
      git.add_tag "2026jun09-1610-c17fe6f-v1", nil, annotate: true, f: true, message: "For testing"
      git.push
      git.branch("test-branch").checkout
      git.commit("test message", allow_empty: true)
      git.branch("master").checkout

      run_ed "deploy production -r test-branch"

      deploy_tag = git.object "#{git.tags.filter { |tag| tag.name.start_with? "deploy-production" }.first.name}^{}"
      branch = git.object "test-branch"

      expect(deploy_tag.sha).to eq branch.sha
    end
  end

  context "given that EpiDeploy.use_timestamped_deploy_tags is configured to false" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.use_timestamped_deploy_tags = false
      RUBY
    end

    specify "it prints a deprecation warning that prompts me to switch to using tags" do
      git.add_tag "2026jun09-1610-c17fe6f-v1", nil, annotate: true, f: true, message: "For testing"
      git.push

      run_ed "deploy production"

      expect(all_output).to include "[Deprecation Warning] Branchless deployments will be the only option"
    end
  end

  context "given that EpiDeploy.use_tags_for_deploy is configured" do
    before do
      write_file "config/epi_deploy.rb", <<~RUBY
        EpiDeploy.use_tags_for_deploy = true
      RUBY
    end

    specify "it exits with an error" do
      run_ed "deploy production"

      expect(all_output).to include "The use_tags_for_deploy option is now obsolete. It has been superseded by use_timestamped_deploy_tags."
      expect(last_command_started).not_to have_exit_status(0)
    end
  end
end
