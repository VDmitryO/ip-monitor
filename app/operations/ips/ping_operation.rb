require 'net/ping'

module App
  module Ips
    module PingOperation
      PING_TIMEOUT = 1  # seconds - hard requirement

      module_function

      def call(ip)
        address = ip[:address].to_s
        puts "[PingOperation] Pinging #{address} (id=#{ip[:id]})"

        pinger = Net::Ping::External.new(address, nil, PING_TIMEOUT)

        success = pinger.ping?
        response_time_ms = success && pinger.duration ? (pinger.duration * 1000).round(2) : nil
        error_message = success ? nil : (pinger.exception || 'ping failed')

        puts "[PingOperation] #{address}: success=#{success}, response_time_ms=#{response_time_ms}, error_message=#{error_message}"

        App::PingCheck.create(
          ip_id: ip[:id],
          checked_at: Time.now,
          success: success,
          response_time_ms: response_time_ms,
          error_message: error_message
        )
      rescue => e
        puts "[PingOperation] Error pinging #{address}: #{e.message}"

        App::PingCheck.create(
          ip_id: ip[:id],
          checked_at: Time.now,
          success: false,
          error_message: "Exception: #{e.message}"
        )
      end
    end
  end
end
