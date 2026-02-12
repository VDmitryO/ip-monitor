module App
  class Ip < Sequel::Model
    plugin :timestamps, update_on_create: true
    plugin :validation_helpers

    def validate
      super
      validates_presence [:address]
    end
  end
end
