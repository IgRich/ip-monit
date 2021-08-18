require_relative '../../app/services/ping_service'

RSpec.describe PingService do
  let(:ping_service) { described_class.new }

  let(:accessible_ip) { '127.0.0.1' }
  let(:inaccessible_ip) { '8.8.8.255' }

  describe 'ping' do
    it 'accessible address' do
      result = ping_service.ping(accessible_ip, 1)
      expect(result).to include "#{accessible_ip} ping statistics"
      expect(result).to include '1 packets transmitted, 1 received, 0% packet loss'
    end

    it 'inaccessible address' do
      result = ping_service.ping(inaccessible_ip, 1)
      expect(result).to include "#{inaccessible_ip} ping statistics"
      expect(result).to include '1 packets transmitted, 0 received, 100% packet loss'
    end
  end

  describe 'get_ping_stats' do
    it 'expect valid result format for accessible address' do
      result = ping_service.get_ping_stats(accessible_ip, 5)
      expect(result.min.to_f).to be > 0
      expect(result.max.to_f).to be > 0
      expect(result.avg.to_f).to be > 0
      expect(result.mdev.to_f).to be > 0
      expect(result.transmitted.to_i).to eq 5
      expect(result.received.to_i).to eq 5
      expect(result.package_loss_percents.to_i).to eq 0
    end

    it 'expect valid result format for inaccessible address' do
      result = ping_service.get_ping_stats(inaccessible_ip, 5)
      expect(result.min.to_f).to eq 0
      expect(result.max.to_f).to eq 0
      expect(result.avg.to_f).to eq 0
      expect(result.mdev.to_f).to eq 0
      expect(result.transmitted.to_i).to eq 5
      expect(result.received.to_i).to eq 0
      expect(result.package_loss_percents.to_i).to eq 100
    end
  end

end