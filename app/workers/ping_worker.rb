require 'net/ping'

module App
  class PingWorker
    BATCH_SIZE     = ENV.fetch('PING_BATCH_SIZE', 10).to_i
    CHECK_INTERVAL = ENV.fetch('PING_CHECK_INTERVAL', 60).to_i  # seconds between checks for each IP
    POLL_INTERVAL  = ENV.fetch('PING_POLL_INTERVAL', 5).to_i    # seconds to sleep when no IPs are due
    PING_TIMEOUT   = 1  # seconds - hard requirement

    def run
      puts "[PingWorker] Starting with BATCH_SIZE=#{BATCH_SIZE}, CHECK_INTERVAL=#{CHECK_INTERVAL}s, POLL_INTERVAL=#{POLL_INTERVAL}s"
      
      loop do
        ips = claim_batch
        if ips.any?
          puts "[PingWorker] Processing batch of #{ips.size} IPs"
          ips.each { |ip| ping_and_record(ip) }
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
          .where { next_check_at <= Sequel::CURRENT_TIMESTAMP }
          .order(:next_check_at)
          .limit(BATCH_SIZE)
          .for_update
          .skip_locked
          .all

        return [] if rows.empty?

        ids = rows.map { |r| r[:id] }
        DB[:ips]
          .where(id: ids)
          .update(next_check_at: Sequel.lit("NOW() + interval '#{CHECK_INTERVAL} seconds'"))

        rows
      end
    end

    def ping_and_record(ip_row)
      address = ip_row[:address].to_s
      puts "[PingWorker] Pinging #{address} (id=#{ip_row[:id]})"

      pinger = Net::Ping::External.new(address, nil, PING_TIMEOUT)

      success = pinger.ping?
      response_time_ms = success && pinger.duration ? (pinger.duration * 1000).round(2) : nil
      error_message = success ? nil : (pinger.exception || 'ping failed')

      App::PingCheck.create(
        ip_id: ip_row[:id],
        checked_at: Time.now,
        success: success,
        response_time_ms: response_time_ms,
        error_message: error_message
      )
      puts "[PingWorker] #{address}: success: #{success}, response_time_ms: #{response_time_ms}, error_message: #{error_message}"
    rescue => e
      puts "[PingWorker] Error pinging #{address}: #{e.message}"

      App::PingCheck.create(
        ip_id: ip_row[:id],
        checked_at: Time.now,
        success: false,
        error_message: "Exception: #{e.message}"
      )
    end
  end
end
