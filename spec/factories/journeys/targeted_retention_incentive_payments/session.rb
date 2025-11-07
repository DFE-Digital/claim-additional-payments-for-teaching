FactoryBot.define do
  factory :targeted_retention_incentive_payments_session, class: "Journeys::TargetedRetentionIncentivePayments::Session" do
    journey { Journeys::TargetedRetentionIncentivePayments.routing_name }
  end
end
