module EpiDeploy
  module Helpers

    COLOUR_RED    = "\x1B[31m"
    COLOUR_GREEN  = "\x1B[32m"
    COLOUR_RESET  = "\x1B[0m"

    def print_notice(message)
      $stdout.puts message
    end

    def print_success(message)
      $stdout.puts "#{COLOUR_GREEN}#{message}#{COLOUR_RESET}"
    end

    def print_error(message)
      $stderr.puts "#{COLOUR_RED}#{message}#{COLOUR_RESET}"
    end

    def print_failure_and_abort(message)
      Kernel.abort "#{COLOUR_RED}#{message}#{COLOUR_RESET}"
    end

  end
end
