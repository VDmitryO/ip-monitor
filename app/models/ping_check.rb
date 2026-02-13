module App
  class PingCheck < Sequel::Model
    plugin :timestamps, update_on_create: true
    plugin :validation_helpers

    many_to_one :ip

    def validate
      super
      validates_presence [:ip_id, :checked_at, :success]
    end

    def to_api_hash
      {
        id: id,
        ip_id: ip_id,
        checked_at: checked_at.iso8601,
        status_code: status_code,
        response_time_ms: response_time_ms,
        success: success,
        error_message: error_message
      }
    end
  end
end
