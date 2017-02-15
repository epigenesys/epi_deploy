namespace :epi_deploy do
  task :symlink_customer_configs do
    on release_roles :all  do
      execute :ln, '-s', release_path.join("config/customers/customer_settings/#{fetch(:current_customer)}.yml"), release_path.join("config/customer_settings.yml")
    end
  end
end

namespace :deploy_all do
  task :deploy do
    Dir.glob("config/deploy/#{fetch(:stage)}.*.rb").each do |file|
      stage_and_customer = File.basename file, '.rb'
      customer = stage_and_customer[/\.(.+)$/, 1]
      
      puts "Deploying #{customer} to #{fetch(:stage)}"
      system("cap #{stage_and_customer} deploy")
    end
  end
end

task deploy_all: 'deploy_all:deploy'
after 'deploy:updating', 'epi_deploy:symlink_customer_configs'