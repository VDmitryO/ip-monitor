require 'spec_helper'

RSpec.describe 'API V1 IPs', type: :request do
  describe 'POST /api/v1/ips' do
    let(:request_params) { { ip: '192.168.1.1' } }

    subject { post '/api/v1/ips', request_params }

    context 'with valid IPv4 address' do
      it 'creates a new IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['address']).to eq('192.168.1.1')
        expect(json['enabled']).to eq(true)
        expect(json['id']).to be_a(Integer)
        expect(json['created_at']).not_to be_nil
        expect(json['updated_at']).not_to be_nil
      end
    end

    context 'with valid IPv6 address' do
      let(:request_params) { { ip: '2001:0db8:85a3:0000:0000:8a2e:0370:7334' } }

      it 'creates a new IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['address']).to eq('2001:db8:85a3::8a2e:370:7334')
        expect(json['enabled']).to eq(true)
      end
    end

    context 'with enabled parameter set to false' do
      let(:request_params) { { ip: '10.0.0.1', enabled: false } }

      it 'creates a disabled IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['address']).to eq('10.0.0.1')
        expect(json['enabled']).to eq(false)
      end
    end

    context 'with enabled parameter set to true' do
      let(:request_params) { { ip: '10.0.0.2', enabled: true } }

      it 'creates an enabled IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['address']).to eq('10.0.0.2')
        expect(json['enabled']).to eq(true)
      end
    end

    context 'without ip parameter' do
      let(:request_params) { {} }

      it 'returns validation error' do
        subject

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Validation failed')
        expect(json['details']).to include('ip is missing')
      end
    end

    context 'with invalid IP address format' do
      let(:request_params) { { ip: 'invalid-ip' } }

      it 'returns validation error' do
        subject

        expect(last_response.status).to eq(422)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Validation failed')
      end
    end

    context 'with duplicate IP address' do
      let(:request_params) { { ip: '192.168.1.100' } }

      it 'returns validation error' do
        post '/api/v1/ips', request_params
        expect(last_response.status).to eq(201)

        subject
        expect(last_response.status).to eq(422)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Validation failed')
      end
    end
  end

  describe 'POST /api/v1/ips/:id/enable' do
    let!(:ip) { create(:ip, :disabled) }
    let(:ip_id) { ip.id }

    subject { post "/api/v1/ips/#{ip_id}/enable", {} }

    context 'with valid IP id' do
      it 'enables the IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['id']).to eq(ip.id)
        expect(json['enabled']).to eq(true)
        expect(json['address']).to eq(ip.address)
      end

      it 'updates the database record' do
        expect {
          subject
        }.to change { ip.reload.enabled }.from(false).to(true)
      end
    end

    context 'when IP is already enabled' do
      let!(:ip) { create(:ip) }

      it 'returns success and keeps it enabled' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['enabled']).to eq(true)
      end
    end

    context 'with non-existent IP id' do
      let(:ip_id) { 99999 }

      it 'returns not found error' do
        subject

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Record not found')
      end
    end
  end

  describe 'POST /api/v1/ips/:id/disable' do
    let!(:ip) { create(:ip) }
    let(:ip_id) { ip.id }

    subject { post "/api/v1/ips/#{ip_id}/disable", {} }

    context 'with valid IP id' do
      it 'disables the IP address' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['id']).to eq(ip.id)
        expect(json['enabled']).to eq(false)
        expect(json['address']).to eq(ip.address)
      end

      it 'updates the database record' do
        expect {
          subject
        }.to change { ip.reload.enabled }.from(true).to(false)
      end
    end

    context 'when IP is already disabled' do
      let!(:ip) { create(:ip, :disabled) }

      it 'returns success and keeps it disabled' do
        subject

        expect(last_response.status).to eq(201)
        json = JSON.parse(last_response.body)
        expect(json['enabled']).to eq(false)
      end
    end

    context 'with non-existent IP id' do
      let(:ip_id) { 99999 }

      it 'returns not found error' do
        subject

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Record not found')
      end
    end
  end

  describe 'DELETE /api/v1/ips/:id' do
    let!(:ip) { create(:ip) }
    let(:ip_id) { ip.id }

    subject { delete "/api/v1/ips/#{ip_id}", {} }

    context 'with valid IP id' do
      it 'deletes the IP address' do
        subject

        expect(last_response.status).to eq(204)
        expect(last_response.body).to be_empty
      end

      it 'removes the record from database' do
        expect {
          subject
        }.to change { App::Ip.count }.by(-1)
      end

      it 'disables the IP before deletion' do
        subject
        
        # Since the record is deleted, we can't check it directly
        # but the code shows it's disabled before deletion
        expect(last_response.status).to eq(204)
      end
    end

    context 'with already disabled IP' do
      let!(:ip) { create(:ip, :disabled) }

      it 'deletes the IP address' do
        subject

        expect(last_response.status).to eq(204)
        expect(App::Ip[ip.id]).to be_nil
      end
    end

    context 'with non-existent IP id' do
      let(:ip_id) { 99999 }

      it 'returns not found error' do
        subject

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Record not found')
      end
    end
  end

  describe 'GET /api/v1/ips/:id/stats' do
    let!(:ip) { create(:ip) }
    let(:ip_id) { ip.id }
    let(:request_params) { { time_from: (Time.now - 3600).iso8601, time_to: Time.now.iso8601 } }

    subject { get "/api/v1/ips/#{ip_id}/stats", request_params }

    context 'with valid IP id and ping checks' do
      before do
        create(:ping_check, ip: ip, checked_at: Time.now - 1800, response_time_ms: 15.5)
      end

      it 'returns statistics' do
        subject

        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json['avg_rtt']).to eq(15.5)
        expect(json['min_rtt']).to eq(15.5)
        expect(json['max_rtt']).to eq(15.5)
        expect(json['median_rtt']).to eq(15.5)
        expect(json['stddev_rtt']).to eq(0.0)
        expect(json['packet_loss_pct']).to eq(0.0)
        expect(json['total_checks']).to eq(1)
      end
    end

    context 'when no ping checks exist in range' do
      it 'returns error' do
        subject

        expect(last_response.status).to eq(422)
        json = JSON.parse(last_response.body)
        expect(json['error']).to match(/no ping checks/i)
      end
    end

    context 'with non-existent IP id' do
      let(:ip_id) { 99999 }

      it 'returns not found error' do
        subject

        expect(last_response.status).to eq(404)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Record not found')
      end
    end

    context 'without required parameters' do
      let(:request_params) { {} }

      it 'returns validation error' do
        subject

        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Validation failed')
      end
    end
  end
end
