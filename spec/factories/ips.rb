FactoryBot.define do
  factory :ip, class: 'App::Ip' do
    to_create(&:save)
    
    sequence(:address) { |n| Sequel.lit("?::inet", "192.168.1.#{n}") }
    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :ipv6 do
      sequence(:address) { |n| Sequel.lit("?::inet", "2001:db8:85a3::#{n}") }
    end
  end
end
