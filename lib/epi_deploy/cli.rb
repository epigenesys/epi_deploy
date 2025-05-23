require 'slop'

require_relative 'command'

module EpiDeploy
  class Cli
    def run!
      load_config

      Slop.parse strict: true do

        banner 'Usage: bundle exec epi_deploy <command>'
    
        command 'release' do
          description 'Create a new release with optional deploy'
    
          on :d=, :deploy=, 'Deploy to specified environment(s)', argument: :optional, as: Array, delimiter: ':'
    
          run do |options, args|
            command = EpiDeploy::Command.new(options, args)
            command.release
          end
        end
    
        command 'deploy' do
          description 'Deploys an existing release'
    
          on :r=, :ref=, 'Git reference to deploy', argument: :optional
    
          run do |options, args|
            command = EpiDeploy::Command.new(options, args)
            command.deploy
          end
        end
    
        run do |options, args|
          Kernel.abort "\x1B[31mValid commands are 'release' and 'deploy'.\x1B[0m"
        end
    
      end
    rescue Slop::InvalidOptionError, Slop::InvalidArgumentError, RuntimeError => e
      Kernel.abort "\x1B[31m#{e.message}\x1B[0m"
    end

    private

      def load_config
        config_path = File.join(Dir.pwd, 'config/epi_deploy.rb')
        if File.exist?(config_path)
          require config_path
        end
      end
  end
end