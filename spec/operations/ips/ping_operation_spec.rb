require 'spec_helper'
require_relative '../../../app/operations/ips/ping_operation'

RSpec.describe App::Ips::PingOperation do
  let(:ip) { create(:ip) }

  subject { described_class.call(ip) }

  describe '.call' do
    context 'when ping succeeds' do
      before do
        allow(described_class).to receive(:ping_ipv4).and_return([true, 0.025, nil])
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
      before do
        allow(described_class).to receive(:ping_ipv4).and_return([false, nil, 'host unreachable'])
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
      before do
        allow(described_class).to receive(:ping_ipv4).and_return([false, nil, nil])
      end

      it 'records a generic error message' do
        ping_check = subject

        expect(ping_check.error_message).to eq('ping failed')
      end
    end

    context 'when an exception is raised' do
      before do
        allow(described_class).to receive(:ping_ipv4).and_raise(StandardError, 'something broke')
      end

      it 'rescues and records the exception' do
        ping_check = subject

        expect(ping_check).not_to be_nil
        expect(ping_check.success).to be false
        expect(ping_check.error_message).to include('Exception: something broke')
      end
    end

    context 'when pinging IPv4 address' do
      before do
        allow(described_class).to receive(:ping_ipv4).and_return([true, 0.01, nil])
      end

      it 'uses ping_ipv4' do
        subject

        expect(described_class).to have_received(:ping_ipv4).with(ip[:address].to_s)
      end
    end

    context 'when pinging an IPv6 address' do
      let(:ip) { create(:ip, address: '2001:4860:4860::8888') }

      before do
        allow(described_class).to receive(:ping_ipv6).and_return([true, 0.030, nil])
      end

      it 'uses ping_ipv6 instead of Net::Ping::ICMP' do
        ping_check = subject

        expect(described_class).to have_received(:ping_ipv6).with('2001:4860:4860::8888')
        expect(ping_check.success).to be true
        expect(ping_check.response_time_ms).to eq(30.0)
      end
    end

    context 'when pinging an IPv6 address that fails' do
      let(:ip) { create(:ip, address: '2001:4860:4860::8888') }

      before do
        allow(described_class).to receive(:ping_ipv6).and_return([false, nil, 'timeout'])
      end

      it 'records the failure' do
        ping_check = subject

        expect(ping_check.success).to be false
        expect(ping_check.error_message).to eq('timeout')
      end
    end
  end
end
