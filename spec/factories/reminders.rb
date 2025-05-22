FactoryBot.define do
  factory :reminder do
    full_name { Faker::Name.name }
    email_address { Faker::Internet.email }
    journey_class { Journeys.all.sample.to_s }

    trait :with_targeted_retention_incentive_payments_reminder do
      journey_class { Journeys::TargetedRetentionIncentivePayments.to_s }
    end

    trait :with_fe_reminder do
      journey_class { Journeys::FurtherEducationPayments.to_s }
    end

    trait :soft_deleted do
      deleted_at { 1.second.ago }
    end
  end
end
