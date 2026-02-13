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
end
