FactoryBot.define do
  factory :ip, class: 'App::Ip' do
    to_create(&:save)
    
    sequence(:address) { |n| "192.168.1.#{n}" }
    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :ipv6 do
      sequence(:address) { |n| "2001:db8:85a3::#{n}" }
    end
  end
end
