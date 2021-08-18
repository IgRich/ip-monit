require_relative '../../boot'
require_relative '../models/ip_action'
require_relative '../models/ip_addresses'
require_relative '../models/ip_measurements'
require_relative '../services/ping_service'
require_relative '../services/ip_action_service'

IP_ACTION_SERVICE = IpActionService.new(PingService.new)
CURRENT_STATE = {}

def ping_address_thread(ip_address)
  Thread.new(ip_address) do |address|
    loop do
      IP_ACTION_SERVICE.update_ip_available(address)
      sleep(2)
    end
  end
end

def start_ping_address(ip_address)
  return if CURRENT_STATE[ip_address]
  CURRENT_STATE[ip_address] = ping_address_thread(ip_address)
end

def update_ping_ips(ip_actions)
  ip_actions.each do |ip_action|
    case IP_ACTION_SERVICE.perform_ip_action(ip_action)
    when IpActionService::ACTIONS[:on_start]
      start_ping_address(ip_action.address)
    when IpActionService::ACTIONS[:on_stop]
      CURRENT_STATE[ip_action.address]&.exit
      CURRENT_STATE[ip_action.address] = nil
    end
  end
end

def on_start_up
  IpAddress.all.each { |model| start_ping_address(model.address) }
end

def start_life_cycle
  loop do
    update_ping_ips IP_ACTION_SERVICE.ip_actions
    sleep(1)
  end
end

on_start_up
start_life_cycle
