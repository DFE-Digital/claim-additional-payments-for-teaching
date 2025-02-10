FactoryBot.define do
  factory :levelling_up_premium_payments_award, class: "Policies::LevellingUpPremiumPayments::Award" do
    association :school
    academic_year { Journeys.for_policy(Policies::LevellingUpPremiumPayments).configuration.current_academic_year }
    award_amount { 2_000 }
  end
end
