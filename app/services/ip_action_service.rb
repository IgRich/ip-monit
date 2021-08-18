class IpActionService
  attr_accessor :ping_service

  ACTIONS = { on_start: 0, on_stop: 1 }.freeze

  def initialize(ping_service)
    @ping_service = ping_service
  end

  def ip_actions
    IpAction.where(state: IpAction::STATES[:new]).order(:created_at).to_a
  end

  def update_ip_available(address)
    io = StringIO.new
    begin
      performed_at = Time.now
      address_ping_result = ping_service.get_ping_stats(address)
      io.puts "#{address}: #{address_ping_result}"
      IpMeasurement.create(performed_at: performed_at,
                           address: address,
                           min_rtt: address_ping_result.min || 0,
                           max_rtt: address_ping_result.max || 0,
                           avg_rtt: address_ping_result.avg || 0,
                           lost_package_percent: address_ping_result.package_loss_percents
      ) unless address_ping_result.package_loss_percents.nil?
    rescue => error
      io.puts error
    ensure
      puts io.string
      io.close
    end
  end

  def perform_ip_action(ip_action)
    case ip_action.action
    when IpAction::ACTIONS[:create]
      IpAddress.find_or_create(address: ip_action.address)
      result_action = ACTIONS[:on_start]
    when IpAction::ACTIONS[:delete]
      IpAddress.first(address: ip_action.address)&.destroy
      result_action = ACTIONS[:on_stop]
    else
      raise Error("Undefined action type #{ip_action.action}, for ip_actions.id: #{ip_action.id}")
    end

    ip_action.state = IpAction::STATES[:performed]
    ip_action.save

    result_action
  end
end