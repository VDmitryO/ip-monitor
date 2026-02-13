require 'ipaddr'

module App
  class Ip < Sequel::Model
    plugin :timestamps, update_on_create: true
    plugin :validation_helpers

    def validate
      super
      validates_presence [:address]
      validates_unique [:address]
      
      # Validate IP address format
      if address && !address.is_a?(Sequel::SQL::Blob)
        begin
          IPAddr.new(address.to_s)
        rescue IPAddr::InvalidAddressError
          errors.add(:address, 'is not a valid IP address')
        end
      end
    end

    def before_save
      super
      # Normalize IP address (e.g., 2001:0db8:... becomes 2001:db8:...)
      if address && !address.is_a?(Sequel::SQL::Blob) && !address.is_a?(Sequel::SQL::PlaceholderLiteralString)
        begin
          normalized = IPAddr.new(address.to_s).to_s
          self.address = normalized
        rescue IPAddr::InvalidAddressError
          # Will be caught by validation
        end
      end
    end

    def to_api_hash
      {
        id: id,
        address: address.to_s,
        enabled: enabled,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601
      }
    end
  end
end
