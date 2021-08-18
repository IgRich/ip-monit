require_relative '../boot'
Bundler.require(:test) # load all the default gems
Bundler.require(Sinatra::Base.environment) # load all the environment specific gems

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # for requests methods
  config.include Rack::Test::Methods

  # coverage config
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/migrations/'
    add_filter '/lib/'
    add_filter '/config/'

    add_group 'Errors', 'app/errors'
    add_group 'Helpers', 'app/helpers'
    add_group 'Models', 'app/models'
    add_group 'Services', 'app/services'
    add_group 'Workers', 'app/workers'
  end
  SimpleCov.coverage_dir 'tmp/coverage'

  # customs hooks, prepare database
  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner[:sequel].strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner[:sequel].start
  end

  config.after(:each) do
    DatabaseCleaner[:sequel].clean
  end
end
