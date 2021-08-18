require_relative '../boot'
require 'sinatra/base'
require 'sinatra/reloader'
require_relative './models/ip_action'
require_relative './models/ip_addresses'
require_relative './models/ip_measurements'
require_relative './errors/param_must_be_present_error'
require_relative './errors/invalid_ip_address'
require_relative './errors/ip_address_not_found'
require_relative './errors/ip_address_already_exists'
require_relative './helpers/validate_helper'
require_relative './helpers/response_helper'

class PingApp < Sinatra::Application
  set :bind, '0.0.0.0'
  set :port, 9494
  set :show_exceptions, false

  helpers ResponseHelper, ValidateHelper

  configure :development do
    register Sinatra::Reloader
  end

  before do
    content_type 'application/json'
  end

  get "/ip_address/stat" do
    stat_result = IpMeasurement.make_report(ip_address, date_param(:date_from), date_param(:date_to))
    stat_result.nil? ? empty_response : stat_result.to_json
  end

  post "/ip_address" do
    raise IpAddressAlreadyExists.new(ip_address) unless IpAddress.find(address: ip_address).nil?
    IpAction.create(address: ip_address, action: IpAction::ACTIONS[:create])
    success_response
  end

  delete "/ip_address" do
    raise IpAddressNotFound.new(ip_address) if IpAddress.find(address: ip_address).nil?
    IpAction.create(address: ip_address, action: IpAction::ACTIONS[:delete])
    success_response
  end

  error do
    case env['sinatra.error'].class.name
    when 'JSON::ParserError'
      error_message = 'Params must be json!'
    when 'InvalidIpAddress', 'ParamMustBePresentError', 'Date::Error', 'IpAddressAlreadyExists', 'IpAddressNotFound'
      error_message = env['sinatra.error'].message
    else
      error_message = 'Internal server error!'
    end
    error_response(error_message)
  end

  not_found do
    not_found_response
  end
end




