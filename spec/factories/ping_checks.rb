FactoryBot.define do
  factory :ping_check, class: 'App::PingCheck' do
    to_create(&:save)

    association :ip
    checked_at { Time.now }
    success { true }
    response_time_ms { rand(5.0..100.0).round(2) }
    error_message { nil }

    trait :failed do
      success { false }
      response_time_ms { nil }
      error_message { 'timeout' }
    end
  end
end
