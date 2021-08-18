class InvalidIpAddress < StandardError
  def initialize(ip_address)
    super("Invalid ip address: '#{ip_address}'!")
  end
end