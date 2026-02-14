module App
  module Ips
    module StatsOperation
      module_function

      def call(ip, time_from, time_to)
        dataset = DB[<<~SQL, ip.id, time_from, time_to]
          SELECT
            COUNT(*)                                              AS total_checks,
            AVG(response_time_ms)                                 AS avg_rtt,
            MIN(response_time_ms)                                 AS min_rtt,
            MAX(response_time_ms)                                 AS max_rtt,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time_ms) AS median_rtt,
            STDDEV_POP(response_time_ms)                          AS stddev_rtt,
            (COUNT(*) FILTER (WHERE success = false)::float
              / NULLIF(COUNT(*), 0) * 100)                        AS packet_loss_pct
          FROM ping_checks
          WHERE ip_id = ?
            AND checked_at >= ?
            AND checked_at <= ?
        SQL

        row = dataset.first

        if row[:total_checks] > 0
          success_response(row)
        else
          fail_response
        end
      end

      def success_response(row)
        {
          success: true,
          data: {
            avg_rtt:         row[:avg_rtt]&.round(2),
            min_rtt:         row[:min_rtt]&.round(2),
            max_rtt:         row[:max_rtt]&.round(2),
            median_rtt:      row[:median_rtt]&.round(2),
            stddev_rtt:      row[:stddev_rtt]&.round(2),
            packet_loss_pct: row[:packet_loss_pct]&.round(2),
            total_checks:    row[:total_checks]
          }
        }
      end

      def fail_response
        {
          success: false,
          message: 'No ping checks found for this IP in the given time range'
        }
      end
    end
  end
end
