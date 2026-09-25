FactoryBot.define do
  factory :school_targeted_retention_incentive_payments_session, class: "Journeys::SchoolTargetedRetentionIncentivePayments::Session" do
    journey { Journeys::SchoolTargetedRetentionIncentivePayments.routing_name }
  end
end
