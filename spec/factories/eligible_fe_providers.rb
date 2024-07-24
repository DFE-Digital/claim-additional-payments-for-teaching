FactoryBot.define do
  factory :eligible_fe_provider do
    ukprn { rand(10_000_000..19_000_000) }
    academic_year { AcademicYear.current }
    max_award_amount { [4_000, 5_000, 6_000].sample }
    lower_award_amount { [2_000, 2_500, 3_000].sample }
  end
end
