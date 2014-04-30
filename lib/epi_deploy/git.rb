# TODO: check for uncommitted changes at the start of each task
# TODO: Should crap out if git error?
# TODO: Be able to config live branches in app?

namespace :git do

  def version_file_path
    Rails.root.join('config/initializers/version.rb')
  end
  
  def read_app_version
    load version_file_path
    APP_VERSION
  end
  
  def write_app_version(v)
    File.open(version_file_path, 'w') { |f| f.write("APP_VERSION = '#{v}'") }
    load version_file_path
  end
  
  def major_version_bump(current_version = read_app_version)
    version_number_array = current_version.split('.')
    version_number_array[0] = version_number_array[0].to_i + 1
    version_number_array[1] = 0
    version_number_array[2] = 0
    version_number_array.join('.').to_s
  end
  
  def minor_version_bump(current_version = read_app_version)
    version_number_array = current_version.split('.')
    version_number_array[1] = version_number_array[1].to_i + 1
    version_number_array[2] = 0 # When bumping minor version reset bugfix version
    version_number_array.join('.').to_s
  end
  
  def hotfix_version_bump(current_version = read_app_version)
    version_number_array = current_version.split('.')
    version_number_array[2] = version_number_array[2].to_i + 1
    version_number_array.join('.').to_s
  end
  
  def all_branches
    `git branch -a`
  end
  
  def uncommited_changes?
    !`git diff && git diff --cached`.blank?
  end
  
  def branch_exists?(live_branch)
     all_branches =~ /[\s\/]#{live_branch}$/
  end

  def current_branch_name
    `git rev-parse --abbrev-ref HEAD`
  end

  def current_branch?(branch)
    current_branch_name =~ /^#{branch}-/
  end

  def confirm?(question)
    print "\x1B[36m\033[1m#{question}\x1B[0m"
    proceed = STDIN.gets[0..0] rescue nil
    (proceed == 'y' || proceed == 'Y')
  end

  def error(message)
    puts "\x1B[31mError: #{message}\x1B[0m" 
  end

  def deploy?(server)
    if confirm?("Would you like to deploy to the #{server} server? (y/n)")
      `cap #{server} deploy:migrations`
    end
  end

  def merge_and_tag(source, target, version)
    print "Merging and tagging #{source} to #{target}... "
    `git checkout #{target}`
    `git pull`
    `git merge #{source}`
    `git tag -a v#{version} -m "Version #{version}"`
    `git push origin #{target}`
    puts  "\x1B[32m OK \x1B[0m"
  end

  def uncommitted_changes?
    !(`git diff-index HEAD`.blank?)
  end

  def can_create_tag?(branch)
    branch != 'production' &&  branch != 'training' 
  end
  
  desc "Run this task at the start to check your repository is set up correctly and create the necessary branches if they don't exist."
  task setup: :environment do
    print " - Checking git repo..."
    if Dir.exist?('.git')
      puts  "\x1B[32m OK \x1B[0m"
      branch = current_branch_name
      puts " - Checking branch structure..."
      required_branches = %w(master demo production qa)
      existing_branches = all_branches.scan(/#{required_branches.join('|')}/).to_set
      
      required_branches.each do |required_branch|
        print "   #{required_branch}..."
        if existing_branches.member?(required_branch)
          puts "\x1B[32m OK \x1B[0m"
        else
          `git checkout -b #{required_branch}`
          `git push -u origin #{required_branch}`
          puts "\x1B[32m created \x1B[0m"
        end  
      end
      `git checkout #{branch}` unless branch == current_branch_name
      print  " - Checking version file..."
      unless File.exist?(version_file_path)
        print "creating #{version_file_path}..."
        write_app_version('0.0.0')
      end
      puts  "\x1B[32m OK \x1B[0m"
    else
      error("Please init a repo with a master branch and push it to the server first.")
    end
  end

  ##
  # This method is intended to handle the alternate workflow for ticket-based projects.
  # This allows a project to deploy a specific branch to a specific demo site.
  # Both arguments must be given for this to work correctly.
  def demo_workflow(args)
    error "Both the demo and the branch values must be given." unless args.demo && args.branch
    demo_site = "demo#{args.demo}"

    unless branch_exists? demo_site
      if confirm?("The branch #{demo_site} does not exist. Do you want to create it now?")
        `git checkout -b #{demo_site}`
        `git push -u origin #{demo_site}`
        puts "\x1B[32m created \x1B[0m"
      else
        error "The branch #{demo_site} does not exist and was not created."
      end
    end
    if uncommitted_changes?
      error "There are uncommitted changes on your current branch. Please commit these changes before continuing."
    else
      `git checkout #{args.branch}`
      `git push origin #{demo_site} --force`

      deploy? "#{demo_site}"

      puts "\x1B[32m OK \x1B[0m"
    end
  end
  
  def workflow_for(env_name)
    if branch_exists? env_name
      if uncommited_changes?
        error "There are uncommited changes on your current branch. Please commit these changes before continuing."
      else
        branch = current_branch_name
        if can_create_tag?(env_name) && confirm?("Do you want to create a new tag? If not you can choose an existing one? (y/n)")
          new_version = minor_version_bump
          write_app_version new_version
          selected = "v#{new_version}"
          `git commit #{version_file_path} -m "Bumped to version #{new_version}"`
          `git tag -a v#{new_version} -m "Version #{new_version}"`
          `git push origin master --tags`
        else
          tags = `git tag`.split.sort_by { |ver| ver[/[\d.]+/].split('.').map(&:to_i) }.reverse

          first_tag = tags.first
          recent_tags = tags[1..5]

          puts "The most recent tag is: #{first_tag}"
          puts "Other recent tags are:"
          puts recent_tags.map.with_index {|ver, i| "- #{ver}" }.join("\n")

          selected = nil

          while selected.nil? do
            puts
            puts "\x1B[36m\033[1mWhich tag do you want to deploy to #{env_name}?\x1B[0m (default: #{first_tag})"
            puts
            input = (STDIN.gets[/v[\.\d]+/] rescue nil) || first_tag

            selected = tags.include?(input) ? input : nil
            puts "Invalid tag selected" unless selected
          end

          puts
          puts "\x1B[36m\033[1mDeploying tag #{selected} to #{env_name}...\x1B[0m"
        end

        `git checkout #{env_name}`
        `git pull`

        `git merge --no-edit --no-ff #{selected}`
        `git push origin #{env_name}`

        deploy? env_name

        puts "\x1B[32m OK \x1B[0m"

        `git checkout #{branch}` unless branch == current_branch_name
      end
    else
      error "The #{env_name} branch does not exist."
    end
  end
  
  namespace :production do
    desc "When you're ready to deploy to production run this task. You will be prompted to choose which version (tag) to merge into the production branch and optionally deploy."
    task release: :environment do
      workflow_for('production')
    end
  end
  
  namespace :training do
    desc "When you're ready to deploy to training run this task. You will be prompted to choose which version (tag) to merge into the training branch and optionally deploy."
    task release: :environment do
      workflow_for('training')
    end
  end

  namespace :qa do
    desc "When you're ready to deploy to qa run this task. You will be prompted to choose which version (tag) to merge into the qa branch and optionally deploy."
    task release: :environment do
      workflow_for('qa')
    end
  end

  namespace :demo do
    desc "When you're ready to deploy to demo run this task. You will be prompted to choose which version (tag) to merge into the demo branch and optionally deploy."
    task :release, [:demo, :branch] => [:environment] do |t, args|
      if args.blank?
        workflow_for('demo')
      else
        demo_workflow(args)
      end
    end
  end

  
  ### HOTFIX BRANCHES ###
  # May branch off from: a live branch
  # Must merge back to: the live branch it was branched from and master
  # Naming convention: hotfix-<live branch name>-<version number (bumped)>
  
  # Hotfix branches are created from a live branch. For example, say version 1.2 is the current release running on 
  # production and causing troubles due to a severe bug, but changes on master are yet unstable. We may then make a hotfix 
  # branch from production and start fixing the problem.
  
  desc "This will create a hotfix branch from the live branch specified and bump the version ready for you to implement the fix."
  task :start_hotfix_for, [:live_branch] => :environment do |t, args|
    if uncommitted_changes?
      error "There are uncommited changes on your current branch. Please commit these changes before continuing."
    else
      live_branch = args[:live_branch]
      if branch_exists?(live_branch)
        `git checkout #{live_branch}`
        `git pull`
        new_version = hotfix_version_bump
  
        hotfix_branch = "hotfix-#{live_branch}-#{new_version}" # live_branch included in the name so we know where to merge when we apply the fix
        `git checkout -b #{hotfix_branch} #{live_branch}`
      
        print "Bumping app version to #{new_version}..."
        write_app_version(new_version)
        puts  "\x1B[32m OK \x1B[0m"
      
        print "Committing version bump..."
        `git commit -am "Bumped to version #{new_version} for hotfix"`
        puts  "\x1B[32m OK \x1B[0m"
      
        puts "You are now on branch #{hotfix_branch}. Fix the bug, commit, then run rake git:apply_hotfix"
      else
        error("The branch #{live_branch} does not exist.")
      end
    end
  end
  
  desc "This will merge your hotfix into the appropriate live branch and optionally deploy. You should then manually merge the hotfix into deploy and master if necessary and delete the hotfix branch. Note: you must be in the hotfix branch you wish to apply before running this task."
  task apply_hotfix: :environment do
    if uncommitted_changes?
      error "There are uncommited changes on your current branch. Please commit these changes before continuing."
    else
      if current_branch?(:hotfix)
        version = read_app_version
        hotfix_branch = current_branch_name
        live_branch = hotfix_branch.match(/^hotfix-(?<live_branch>.*)-[^-]+$/)[:live_branch]

        merge_and_tag(hotfix_branch, live_branch, version)
        deploy?(live_branch)

        puts "The hotfix has been applied to #{live_branch}."
        puts "IMPORTANT: You should merge the hotfix branch into demo and master if necessary, then delete the hotfix branch."
      else
        error("Please checkout the hotfix branch you wish to apply.")
      end
    end
  end
  
  
  
  # Staging instead of demo (for MSCAA) - to be standardised at some point
  namespace :staging do
    desc "When you're ready to deploy a release to staging from master run this task. The minor version number will be bumped, the commit tagged and merged into staging (and pushed to origin). Optional deployment."
    task release: :environment do
      if branch_exists? 'staging'
        if uncommited_changes?
          error "There are uncommited changes on your current branch. Please commit these changes before continuing."
        else
          if confirm?('This will merge the master branch to staging for a new release. Continue? (y/n)')
            branch = current_branch_name
            `git checkout master`
            `git pull`
            new_version = minor_version_bump
            write_app_version new_version

            `git commit #{version_file_path} -m "Bumped to version #{new_version}"`
            `git tag -a v#{new_version} -m "Version #{new_version}"`
            `git push origin master`

            `git checkout staging`
            `git pull`

            `git merge --no-edit --no-ff v#{new_version}`
            `git push origin staging`

            deploy? 'staging'  
            puts  "\x1B[32m OK \x1B[0m"
            `git checkout #{branch}` unless branch == current_branch_name
          end
        end
      else
        error "The staging branch does not exist."
      end
    end
  end
  
end
