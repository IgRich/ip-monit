class IpAddressAlreadyExists < StandardError
  def initialize(ip_address)
    super("Ip address already exists: '#{ip_address}'!")
  end
end

