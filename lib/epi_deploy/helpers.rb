module EpiDeploy
  module Helpers

    def print_success(message)
      $stdout.puts "\x1B[32m#{message}\x1B[0m" 
    end

    def print_failure_and_abort(message)
      Kernel.abort "\x1B[31m#{message}\x1B[0m"
    end
    
    def print_notice(message)
      $stdout.puts message
    end
  
  end
end