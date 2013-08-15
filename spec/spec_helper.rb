if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start
end

require 'bogus/rspec'

require 'vocker'

Bogus.configure do |c|
  c.search_modules << VagrantPlugins::Vocker
  c.search_modules << Vagrant
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
