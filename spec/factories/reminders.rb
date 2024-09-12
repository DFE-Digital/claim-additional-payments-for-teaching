FactoryBot.define do
  factory :reminder do
    full_name { Faker::Name.name }
    email_address { Faker::Internet.email }
    journey_class { Journeys::AdditionalPaymentsForTeaching }
  end
end
