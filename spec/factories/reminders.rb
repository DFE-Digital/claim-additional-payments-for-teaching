FactoryBot.define do
  factory :reminder do
    full_name { Faker::Name.name }
    email_address { Faker::Internet.email }
    journey_class { Journeys.all.sample.to_s }

    trait :with_additonal_payments_reminder do
      journey_class { Journeys::AdditionalPaymentsForTeaching.to_s }
    end

    trait :with_fe_reminder do
      journey_class { Journeys::FurtherEducationPayments.to_s }
    end
  end
end
