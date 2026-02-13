require 'spec_helper'
require_relative '../../app/workers/ping_worker'

RSpec.describe App::PingWorker do
  let!(:worker) { described_class.new }

  describe '#claim_batch (via send)' do
    subject(:claim_batch) { worker.send(:claim_batch) }

    context 'when IPs are due for checking' do
      let!(:ip) { create(:ip, next_check_at: Time.now - 10) }

      it 'returns the IPs' do
        expect(claim_batch.size).to eq(1)
        expect(claim_batch.first[:id]).to eq(ip.id)
      end

      it 'advances next_check_at after claiming' do
        claim_batch
        ip.reload
        expect(ip.next_check_at).to be > Time.now
      end
    end

    context 'when IPs are disabled' do
      let!(:ip) { create(:ip, :disabled, next_check_at: Time.now - 10) }

      it 'does not return them' do
        expect(claim_batch).to be_empty
      end
    end

    context 'when IPs are not yet due' do
      let!(:ip) { create(:ip, next_check_at: Time.now + 3600) }

      it 'does not return them' do
        expect(claim_batch).to be_empty
      end
    end

    context 'when more IPs than BATCH_SIZE are due' do
      before { 15.times { create(:ip, next_check_at: Time.now - 10) } }

      it 'respects BATCH_SIZE limit' do
        expect(claim_batch.size).to be <= described_class::BATCH_SIZE
      end
    end
  end

  describe '#ping_and_record (via send)' do
    subject(:ping_and_record) { worker.send(:ping_and_record, ip_row) }

    let(:ip) { create(:ip) }
    let(:ip_row) { DB[:ips].where(id: ip.id).first }
    let(:ping_check) { App::PingCheck.where(ip_id: ip.id).first }

    context 'when ping succeeds' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: true, duration: 0.025, exception: nil) }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
        ping_and_record
      end

      it 'creates a successful PingCheck record' do
        expect(ping_check).not_to be_nil
        expect(ping_check.success).to be true
        expect(ping_check.response_time_ms).to eq(25.0)
        expect(ping_check.error_message).to be_nil
      end
    end

    context 'when ping fails' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: false, duration: nil, exception: 'host unreachable') }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
        ping_and_record
      end

      it 'creates a failed PingCheck record' do
        expect(ping_check).not_to be_nil
        expect(ping_check.success).to be false
        expect(ping_check.response_time_ms).to be_nil
        expect(ping_check.error_message).to eq('host unreachable')
      end
    end

    context 'when ping fails without exception message' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: false, duration: nil, exception: nil) }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
        ping_and_record
      end

      it 'records a generic error message' do
        expect(ping_check.error_message).to eq('ping failed')
      end
    end

    context 'when an exception is raised' do
      before do
        allow(Net::Ping::External).to receive(:new).and_raise(StandardError, 'something broke')
        ping_and_record
      end

      it 'rescues and records the exception' do
        expect(ping_check).not_to be_nil
        expect(ping_check.success).to be false
        expect(ping_check.error_message).to include('Exception: something broke')
      end
    end

    context 'when creating the pinger' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: true, duration: 0.01, exception: nil) }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
        ping_and_record
      end

      it 'uses PING_TIMEOUT' do
        expect(Net::Ping::External).to have_received(:new).with(ip_row[:address].to_s, nil, described_class::PING_TIMEOUT)
      end
    end
  end
end
