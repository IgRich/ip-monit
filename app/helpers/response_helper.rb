require 'sinatra/base'

module ResponseHelper
  def success_response
    status 200
    { status: 'success' }.to_json
  end

  def empty_response
    status 200
    { status: 'error', message: 'empty data' }.to_json
  end

  def error_response(message)
    status 200
    { status: 'error', message: message }.to_json
  end

  def not_found_response
    status 404
    { status: 'not found' }.to_json
  end
end