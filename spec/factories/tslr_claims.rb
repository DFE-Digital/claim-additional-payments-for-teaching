FactoryBot.define do
  factory :tslr_claim do
    trait :eligible_and_submittable do
      claim_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      qts_award_year { "2013-2014" }
      employment_status { :claim_school }
      mostly_teaching_eligible_subjects { true }
      full_name { "Jo Bloggs" }
      address_line_1 { "1 Test Road" }
      address_line_3 { "Test Town" }
      postcode { "AB1 2CD" }
      date_of_birth { 20.years.ago.to_date }
      teacher_reference_number { "1234567" }
      national_insurance_number { "QQ123456C" }
      student_loan_repayment_amount { 1000 }
      email_address { "test@email.com" }
    end

    trait :eligible_but_unsubmittable do
      eligible_and_submittable
      email_address { nil }
    end
  end
end
