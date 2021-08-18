require_relative '../app/ping_app'

RSpec.describe PingApp do
  def app
    PingApp
  end

  def response
    JSON.parse(last_response.body, :symbolize_names => true)
  end

  describe '404 routes' do
    it 'expect custom message' do
      get '/invalid_address'
      expect(last_response.status).to eq 404
      expect(response).to eq({ status: 'not found' })
    end
  end

  describe 'GET /ip_address/stat' do
    let!(:params) do
      { address: '8.8.8.8', date_from: Time.parse('2021-01-01 17:00'), date_to: Time.parse('2021-01-01 22:00') }
    end
    let!(:params_with_empty_stat_ip) { params.merge({ address: '10.10.10.10' }) }
    let!(:params_full_stat_records) { params.merge({ address: '7.7.7.7' }) }
    let!(:measure_1) do
      IpMeasurement.create(performed_at: params_full_stat_records[:date_from],
                           address: params_full_stat_records[:address],
                           min_rtt: 5,
                           max_rtt: 50,
                           avg_rtt: 24,
                           lost_package_percent: 10)
    end
    let!(:measure_2) do
      IpMeasurement.create(performed_at: params_full_stat_records[:date_from],
                           address: params_full_stat_records[:address],
                           min_rtt: 6.66,
                           max_rtt: 51.1111,
                           avg_rtt: 23.16,
                           lost_package_percent: 4)
    end
    let!(:measure_3) do
      IpMeasurement.create(performed_at: params_full_stat_records[:date_from],
                           address: params_full_stat_records[:address],
                           min_rtt: 4.111,
                           max_rtt: 42,
                           avg_rtt: 15,
                           lost_package_percent: 6)
    end
    let!(:measure_4) do
      IpMeasurement.create(performed_at: params_full_stat_records[:date_from],
                           address: params_full_stat_records[:address],
                           min_rtt: 3,
                           max_rtt: 50,
                           avg_rtt: 20,
                           lost_package_percent: 3)
    end
    let!(:measures) { [measure_1, measure_2, measure_3, measure_4] }
    let!(:expected_stat_for_measures) do
      avg_rtt = measures.map(&:avg_rtt).inject { |sum, el| sum + el }.to_f / measures.size
      sum_lost_package = measures.map(&:lost_package_percent).inject { |sum, el| sum + el }.to_f
      sum_rtt_deviation = measures.map(&:avg_rtt).inject(0) { |sum, el| sum + ((el - avg_rtt) ** 2) }.to_f
      {
        max_rtt: measures.map(&:max_rtt).max.round(2),
        min_rtt: measures.map(&:min_rtt).min.round(2),
        avg_rtt: avg_rtt.round(2),
        lost_package_percent: (sum_lost_package / measures.size).round(2),
        median_rtt: (measure_2.avg_rtt + measure_4.avg_rtt) / 2,
        rtt_deviation: (sum_rtt_deviation / (measures.size - 1)).round(2)
      }
    end

    before do
      IpMeasurement.create(performed_at: Time.parse('2021-01-01 20:00'),
                           address: '9.9.9.9',
                           min_rtt: 1.5,
                           max_rtt: 10.5,
                           avg_rtt: 6.333,
                           lost_package_percent: 8)
      IpMeasurement.create(performed_at: Time.parse('2021-01-01 20:00'),
                           address: params[:address],
                           min_rtt: 5.5,
                           max_rtt: 15.5,
                           avg_rtt: 10.333,
                           lost_package_percent: 8)
      IpMeasurement.create(performed_at: Time.parse('2021-01-01 16:00'),
                           address: params[:address],
                           min_rtt: 10,
                           max_rtt: 20.5,
                           avg_rtt: 15.333,
                           lost_package_percent: 20)
      IpMeasurement.create(performed_at: Time.parse('2021-01-01 23:00'),
                           address: params[:address],
                           min_rtt: 8.5,
                           max_rtt: 35.5,
                           avg_rtt: 22.333,
                           lost_package_percent: 50)
    end

    context 'error' do
      it 'without params expect error message' do
        get '/ip_address/stat'
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Params must be json!", status: "error" })
      end

      it 'with only ip params expect error message' do
        get '/ip_address/stat', { address: '127.0.0.1' }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Params must be present: date_from!", status: "error" })
      end

      it 'with invalid date expect error message' do
        get '/ip_address/stat', { address: '127.0.0.1', date_from: 'invalid_date', date_to: Time.now.to_s }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Invalid date for param: date_from!", status: "error" })
      end
    end

    context 'no stats' do
      it 'returns empty message' do
        get '/ip_address/stat', params_with_empty_stat_ip
        expect(last_response.status).to eq 200
        expect(response).to eq({ status: 'error', message: 'empty data' })
      end
    end

    context 'with stats' do
      it 'returns stats filtering by ip and date' do
        get '/ip_address/stat', params
        expect(response).to eq({ avg_rtt: 10.33,
                                 lost_package_percent: 8.0,
                                 max_rtt: 15.5,
                                 median_rtt: 10.33,
                                 min_rtt: 5.5,
                                 rtt_deviation: 0.0 })
      end

      it 'valid stats calculating' do
        get '/ip_address/stat', params_full_stat_records
        expect(response).to eq(expected_stat_for_measures)
      end
    end
  end

  describe 'POST /ip_address' do
    before do
      IpAddress.create(address: '9.9.9.9')
    end
    context 'errors' do
      it 'without param' do
        post '/ip_address'
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Params must be json!", status: "error" })
      end

      it 'with invalid ip' do
        post '/ip_address', { address: 'invalid' }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Invalid ip address: 'invalid'!", status: "error" })
      end

      it 'with exists ip' do
        post '/ip_address', { address: '9.9.9.9' }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Ip address already exists: '9.9.9.9'!", status: "error" })
      end
    end

    context 'success' do
      let(:ip) { '8.8.8.8' }

      def post_request
        post '/ip_address', { address: ip }
      end

      it 'add add command to query' do
        expected = { address: ip, state: IpAction::STATES[:new], action: IpAction::ACTIONS[:create] }

        expect { post_request }.to change(IpAction, :count).by(1)
        expect(IpAction.first(address: ip)).to include(expected)
      end
    end
  end

  describe 'DELETE /ip_address' do
    let(:ip) { '9.9.9.9' }

    before do
      IpAddress.create(address: ip)
    end

    context 'errors' do
      it 'without param' do
        delete '/ip_address'
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Params must be json!", status: "error" })
      end

      it 'with invalid ip' do
        delete '/ip_address', { address: 'invalid' }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Invalid ip address: 'invalid'!", status: "error" })
      end

      it 'with not exists ip' do
        delete '/ip_address', { address: '8.8.8.8' }
        expect(last_response.status).to eq 200
        expect(response).to eq({ message: "Ip address not found: '8.8.8.8'!", status: "error" })
      end
    end

    context 'success' do
      def delete_request
        delete '/ip_address', { address: ip }
      end

      it 'add delete command to query' do
        expected = { address: ip, state: IpAction::STATES[:new], action: IpAction::ACTIONS[:delete] }

        expect { delete_request }.to change(IpAction, :count).by(1)
        expect(IpAction.first(address: ip)).to include(expected)
      end
    end
  end

end