require 'net/ping'
require 'ipaddr'
require_relative '../../utils/logger'

module App
  module Ips
    module PingOperation
      PING_TIMEOUT = 1  # seconds - hard requirement

      module_function

      def call(ip)
        address = ip[:address].to_s
        App::Logger.debug "Pinging address", address: address, ip_id: ip[:id]

        if IPAddr.new(address).ipv6?
          # TODO:
          # My local router does not provide IPv6 connectivity, so only failure cases were tested.
          # This logic should be tested in an IPv6-enabled environment.
          success, duration, error = ping_ipv6(address)
        else
          success, duration, error = ping_ipv4(address)
        end

        response_time_ms = success && duration ? (duration * 1000).round(2) : nil
        error_message = success ? nil : (error || 'ping failed')

        App::Logger.info "Ping completed",
          address: address,
          success: success,
          response_time_ms: response_time_ms,
          error_message: error_message

        App::PingCheck.create(
          ip_id: ip[:id],
          checked_at: Time.now,
          success: success,
          response_time_ms: response_time_ms,
          error_message: error_message
        )
      rescue => e
        App::Logger.error "Ping failed",
          address: address,
          error: e.message,
          backtrace: e.backtrace&.first(5)

        App::PingCheck.create(
          ip_id: ip[:id],
          checked_at: Time.now,
          success: false,
          error_message: "Exception: #{e.message}"
        )
      end

      # IPv4 ping using Net::Ping::ICMP
      def ping_ipv4(address)
        pinger = Net::Ping::ICMP.new(address, nil, PING_TIMEOUT)
        success = pinger.ping?
        duration = pinger.duration
        error = success ? nil : (pinger.exception || 'ping failed')
        [success, duration, error]
      end

      # IPv6 ping using system ping6 command
      def ping_ipv6(address)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        success = system('ping6', '-c', '1', '-W', PING_TIMEOUT.to_s, address,
                         out: File::NULL, err: File::NULL)
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

        if success
          [true, duration, nil]
        else
          [false, nil, 'ping failed']
        end
      end
    end
  end
end
