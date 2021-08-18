require_relative "../errors/param_must_be_present_error"
require_relative "../errors/invalid_ip_address"

module ValidateHelper
  def body_hash_params
    @body_hash_params ||= JSON.parse(request.body.read, :symbolize_names => true)
  end

  def get_hash_params
    @get_hash_params ||= params unless params.empty?
  end

  def hash_params
    @hash_params ||= (get_hash_params || body_hash_params)
  end

  def ip_address
    address = hash_params[:address]
    unless IPAddress.valid? address
      raise InvalidIpAddress.new(address)
    else
      address
    end
  end

  def date_param(param)
    raise ParamMustBePresentError.new(param) unless hash_params[param]
    Time.parse(hash_params[param])
  rescue ArgumentError => error
    raise Date::Error.new("Invalid date for param: #{param}!")
  end
end