require 'fileutils'
require 'lomilomi'
require 'logger'
require 'yaml'

# Auto-generated by lomigen.  Usually, you will not need to modify this file.
# In some special cases, you may need to add, remove, or re-order require statements.

module Chla

  # setup configuration options
  config_file = File.join(File.dirname(__FILE__), '..', 'config', 'config.yml')
  unless File.exists?(config_file)
    puts "Couldn't find config file at #{File.absolute_path(config_file)}"
    exit -1
  end
  CONFIG = YAML.load_file config_file

  # setup default project logger
  log_dir = CONFIG['log_dir']
  FileUtils.mkdir_p(log_dir) unless File.exists?(log_dir)
  LOGGER = Logger.new File.join(CONFIG['log_dir'], CONFIG['project_name'] + '.log'), 'monthly'

end

# Processor classes
require 'processors/patient_match_processor'
# end Processor classes

# Lomi classes
require 'lomis/patient_resolution_lomi'
# end Lomi classes
