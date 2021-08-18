require 'bundler'

ENV['RAKE_ENV'] ||= 'development'
ENV['ROOT_DIR'] ||= File.dirname(__FILE__)

Bundler.require(:default, ENV['RAKE_ENV'].to_sym)

autoload :YAML, 'yaml'

# load database and models
require_relative './lib/db_connection'

# load rake tasks
Dir['lib/**/*.rb'].each { |f| require_relative f }

