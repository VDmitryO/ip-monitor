Sequel.migration do
  change do
    create_table(:ping_checks) do
      primary_key :id
      foreign_key :ip_id, :ips, null: false, on_delete: :cascade

      column      :checked_at,      'timestamptz', null: false
      Integer     :status_code                          # ICMP type/code or HTTP status; NULL if unreachable
      Float       :response_time_ms                     # RTT in ms; NULL on timeout/error
      TrueClass   :success,         null: false         # did the ping succeed?
      String      :error_message,   text: true          # NULL on success

      # 1. Last check per IP + history range scans + stats queries
      index [:ip_id, :checked_at], name: :idx_ping_checks_ip_checked_at

      # 2. Retention cleanup (delete old records globally)
      index [:checked_at], name: :idx_ping_checks_checked_at
    end
  end
end
