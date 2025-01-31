FactoryBot.define do
  factory :targeted_retention_incentive_payments_award, class: "Policies::TargetedRetentionIncentivePayments::Award" do
    association :school
    academic_year { Journeys.for_policy(Policies::TargetedRetentionIncentivePayments).configuration.current_academic_year }
    award_amount { 2_000 }
  end
end
