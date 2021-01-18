$: << File.expand_path('../../lib', __FILE__)

def run_ed(commands)
  run_command_and_stop "#{File.join(File.dirname(__FILE__), '../bin/epi_deploy')} #{commands}", fail_on_error: false
end
