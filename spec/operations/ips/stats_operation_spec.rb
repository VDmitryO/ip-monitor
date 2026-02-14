require 'spec_helper'
require_relative '../../../app/operations/ips/stats_operation'

RSpec.describe App::Ips::StatsOperation do
  let(:ip) { create(:ip, address: '192.168.1.1') }
  let(:time_from) { Time.now - 3600 }
  let(:time_to)   { Time.now }

  subject { described_class.call(ip, time_from, time_to) }

  context 'when ping checks exist' do
    before do
      # 3 successful pings with known RTTs, 1 failed
      [10.0, 20.0, 30.0].each do |rtt|
        create(:ping_check, ip: ip, checked_at: Time.now - 1800, response_time_ms: rtt)
      end
      create(:ping_check, :failed, ip: ip, checked_at: Time.now - 1800)
    end

    it 'returns correct statistics' do
      result = subject

      expect(result[:success]).to be true
      data = result[:data]

      expect(data[:total_checks]).to eq(4)
      expect(data[:avg_rtt]).to eq(20.0)
      expect(data[:min_rtt]).to eq(10.0)
      expect(data[:max_rtt]).to eq(30.0)
      expect(data[:median_rtt]).to eq(20.0)
      expect(data[:stddev_rtt]).to be_within(0.1).of(8.16) # stddev_pop of [10,20,30]
      expect(data[:packet_loss_pct]).to eq(25.0)
    end
  end

  context 'when no ping checks exist in range' do
    it 'returns an error' do
      result = subject

      expect(result[:success]).to be false
      expect(result[:message]).to eq('No ping checks found for this IP in the given time range')
    end
  end

  context 'when checks exist but outside the time range' do
    before do
      create(:ping_check, ip: ip, checked_at: Time.now - 7200, response_time_ms: 15.0)
    end

    it 'returns an error' do
      result = subject

      expect(result[:success]).to be false
      expect(result[:message]).to eq('No ping checks found for this IP in the given time range')
    end
  end
end
