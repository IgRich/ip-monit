class IpAddressNotFound < StandardError
  def initialize(ip_address)
    super("Ip address not found: '#{ip_address}'!")
  end
end
