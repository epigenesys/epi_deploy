module EpiDeploy
  module MessageHelper

    def print_success(text)
      puts  "\x1B[32m#{text}\x1B[0m" 
    end

    def print_failure(text)
      puts "\x1B[31m#{text}\x1B[0m" 
    end

    def print_notice(text)
      puts text
    end
  
  end
end