require_relative '../operations/ips/ping_operation'
require_relative '../utils/logger'

module App
  class PingWorker
    BATCH_SIZE     = ENV.fetch('PING_BATCH_SIZE', 10).to_i
    CHECK_INTERVAL = ENV.fetch('PING_CHECK_INTERVAL', 60).to_i  # seconds between checks for each IP
    POLL_INTERVAL  = ENV.fetch('PING_POLL_INTERVAL', 5).to_i    # seconds to sleep when no IPs are due

    def run
      App::Logger.info "Starting PingWorker", 
        batch_size: BATCH_SIZE, 
        check_interval: CHECK_INTERVAL, 
        poll_interval: POLL_INTERVAL
      
      loop do
        ips = claim_batch
        if ips.any?
          App::Logger.info "Processing batch", batch_size: ips.size
          ips.each { |ip| App::Ips::PingOperation.call(ip) }
        else
          sleep POLL_INTERVAL
        end
      end
    end

    private

    def claim_batch
      DB.transaction do
        rows = DB[:ips]
          .where(enabled: true)
          .where { next_check_at <= Time.now.utc }
          .order(:next_check_at)
          .limit(BATCH_SIZE)
          .for_update
          .skip_locked
          .all

        return [] if rows.empty?

        ids = rows.map { |r| r[:id] }
        DB[:ips]
          .where(id: ids)
          .update(next_check_at: Time.now.utc + CHECK_INTERVAL)

        rows
      end
    end
  end
end
