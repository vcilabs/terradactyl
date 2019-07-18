require_relative 'helpers'

working_dir = File.dirname(__FILE__)
FileUtils.cd(File.join(working_dir, 'fixtures'))

require 'rspec_command'
require 'pry'
require 'bundler/setup'
require 'terradactyl'

RSpec.configure do |config|
  # Load the exra RSpec libs
  config.include RSpecCommand

  # Load the Helpers
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
