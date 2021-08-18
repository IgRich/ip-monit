require_relative '../../app/models/ip_action'
require_relative '../../app/models/ip_addresses'
require_relative '../../app/models/ip_measurements'
require_relative '../../app/services/ping_service'
require_relative '../../app/services/ip_action_service'

RSpec.describe IpActionService do
  let!(:ping_service) { PingService.new }
  let!(:ping_stat) do
    stats = PingService::IpPingStat.new
    stats.min = 1
    stats.avg = 2
    stats.max = 3
    stats.mdev = 4
    stats.transmitted = 10
    stats.received = 8
    stats.package_loss_percents = 20
    stats
  end
  let!(:ip_action_service) { described_class.new(ping_service) }
  let!(:address) { '8.8.8.8' }

  before do
    allow(ping_service).to receive(:get_ping_stats).and_return(ping_stat)
  end

  describe 'ip_actions' do
    before do
      IpAction.create(address: address, state: IpAction::STATES[:new], action: IpAction::ACTIONS[:create])
      IpAction.create(address: address, state: IpAction::STATES[:new], action: IpAction::ACTIONS[:create])
      IpAction.create(address: address, state: IpAction::STATES[:performed], action: IpAction::ACTIONS[:create])
    end

    it 'return only new' do
      expect(ip_action_service.ip_actions.count).to eq(2)
    end
  end

  describe 'update_ip_available' do

    def update_ip_available
      ip_action_service.update_ip_available(address)
    end

    it 'increase ip address measurements' do
      expect { update_ip_available }.to change(IpMeasurement, :count).by(1)
    end

    it 'create valid ip measurement record' do
      expected = {
        address: address,
        avg_rtt: ping_stat.avg,
        lost_package_percent: ping_stat.package_loss_percents,
        max_rtt: ping_stat.max,
        min_rtt: ping_stat.min,
      }

      update_ip_available
      expect(IpMeasurement.last(address: address)).to include(expected)
    end
  end

  describe 'perform_ip_action' do
    context 'create action' do
      let(:exists_ip) { '8.8.8.8' }
      let(:new_ip) { '9.9.9.9' }
      let(:action_for_new_ip) { IpAction.create(address: new_ip, action: IpAction::ACTIONS[:create]) }
      let(:action_for_exist_ip) { IpAction.create(address: exists_ip, action: IpAction::ACTIONS[:create]) }

      before do
        IpAddress.create(address: exists_ip)
      end

      it 'create new ip ' do
        expect { ip_action_service.perform_ip_action(action_for_new_ip) }.to change(IpAddress, :count).by(1)
        expect(IpAddress.where(address: new_ip).count).to eq(1)
      end

      it 'do nothing if exists ip' do
        expect { ip_action_service.perform_ip_action(action_for_exist_ip) }.to change(IpAddress, :count).by(0)
      end

      it 'start tread result' do
        expect(ip_action_service.perform_ip_action(action_for_exist_ip)).to eq IpActionService::ACTIONS[:on_start]
      end
    end

    context 'delete action' do
      let(:exists_ip) { '8.8.8.8' }
      let(:new_ip) { '9.9.9.9' }
      let(:action_for_new_ip) { IpAction.create(address: new_ip, action: IpAction::ACTIONS[:delete]) }
      let(:action_for_exist_ip) { IpAction.create(address: exists_ip, action: IpAction::ACTIONS[:delete]) }

      before do
        IpAddress.create(address: exists_ip)
      end

      it 'remove ip ' do
        expect { ip_action_service.perform_ip_action(action_for_exist_ip) }.to change(IpAddress, :count).by(-1)
        expect(IpAddress.where(address: exists_ip).count).to eq(0)
      end

      it 'do nothing if not exists idp' do
        expect { ip_action_service.perform_ip_action(action_for_new_ip) }.to change(IpAddress, :count).by(0)
      end

      it 'stop tread result' do
        expect(ip_action_service.perform_ip_action(action_for_exist_ip)).to eq IpActionService::ACTIONS[:on_stop]
      end
    end
  end
end