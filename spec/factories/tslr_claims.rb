FactoryBot.define do
  factory :tslr_claim do
    trait :eligible_and_submittable do
      claim_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      current_school { claim_school }
      qts_award_year { "2013-2014" }
      employment_status { :claim_school }
      eligible_subjects { [:physics] }
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
      bank_sort_code { 123456 }
      bank_account_number { 12345678 }
    end

    trait :eligible_but_unsubmittable do
      eligible_and_submittable
      email_address { nil }
    end

    trait :submitted do
      eligible_and_submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end
  end
end
