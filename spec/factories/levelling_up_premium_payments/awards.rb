FactoryBot.define do
  factory :levelling_up_premium_payments_award, class: "LevellingUpPremiumPayments::Award" do
    association :school
    academic_year { AcademicYear.current }
    award_amount { 2_000 }
  end
end
