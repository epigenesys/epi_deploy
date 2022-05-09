namespace :epi_deploy do
  task :symlink_customer_configs do
    on release_roles :all  do
      execute :ln, '-s', release_path.join("config/customers/customer_settings/#{fetch(:current_customer)}.yml"), release_path.join("config/customer_settings.yml")
    end
  end
end

namespace :deploy_all do
  task :deploy do
    iterate_over_customers do |stage_and_customer, customer|
      puts "\u001b[1mDeploying '#{customer}' to '#{fetch(:stage)}'...\u001b[0m"
      system("cap #{stage_and_customer} deploy")
    end
  end

  task :revisions do
    iterate_over_customers do |stage_and_customer, customer|
      puts "\u001b[1mGetting revision for '#{customer}' on '#{fetch(:stage)}'...\u001b[0m"
      system("cap #{stage_and_customer} deploy:revision")
    end
  end
end

namespace :deploy do
  # Source: https://makandracards.com/makandra/10105-capistrano-how-to-find-out-which-version-of-your-application-is-currently-live
  task :revision do
    on roles :app do |host|
      within current_path do
        info "#{fetch(:user)}@#{host}: #{capture :cat, 'REVISION'}"
      end
    end
  end
end

def iterate_over_customers
  Dir.glob("config/deploy/#{fetch(:stage)}.*.rb").sort.each_with_index do |file, index|
    # Extract the variables required
    stage_and_customer = File.basename file, '.rb'
    customer = stage_and_customer[/\.(.+)$/, 1]

    # Insert a blank line between each run
    puts if index > 0

    # Yield back to the caller to run the relevant task
    yield stage_and_customer, customer
  end
end

task deploy_all: 'deploy_all:deploy'
after 'deploy:updating', 'epi_deploy:symlink_customer_configs'
