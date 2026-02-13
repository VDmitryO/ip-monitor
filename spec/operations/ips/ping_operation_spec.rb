require 'spec_helper'
require_relative '../../../app/operations/ips/ping_operation'

RSpec.describe App::Ips::PingOperation do
  let(:ip) { create(:ip) }

  subject { described_class.call(ip) }

  describe '.call' do
    context 'when ping succeeds' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: true, duration: 0.025, exception: nil) }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
      end

      it 'creates a successful PingCheck record' do
        ping_check = subject

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
      end

      it 'creates a failed PingCheck record' do
        ping_check = subject

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
      end

      it 'records a generic error message' do
        ping_check = subject

        expect(ping_check.error_message).to eq('ping failed')
      end
    end

    context 'when an exception is raised' do
      before do
        allow(Net::Ping::External).to receive(:new).and_raise(StandardError, 'something broke')
      end

      it 'rescues and records the exception' do
        ping_check = subject

        expect(ping_check).not_to be_nil
        expect(ping_check.success).to be false
        expect(ping_check.error_message).to include('Exception: something broke')
      end
    end

    context 'when creating the pinger' do
      let(:pinger) { instance_double(Net::Ping::External, ping?: true, duration: 0.01, exception: nil) }

      before do
        allow(Net::Ping::External).to receive(:new).and_return(pinger)
      end

      it 'uses PING_TIMEOUT' do
        subject

        expect(Net::Ping::External).to have_received(:new).with(
          ip[:address].to_s, nil, described_class::PING_TIMEOUT
        )
      end
    end
  end
end
