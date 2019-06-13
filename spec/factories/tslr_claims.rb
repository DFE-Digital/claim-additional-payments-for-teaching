FactoryBot.define do
  factory :tslr_claim do
    trait :eligible_and_submittable do
      # This skips out the `update_current_school` callback, which is used when a user is
      # filling out a form, but stamps all over our definition of a `current_school`
      # if we try to define it in tests
      before(:create) { |claim| claim.class.skip_callback(:save, :before, :update_current_school) }
      after(:create) { |claim| claim.class.set_callback(:save, :before, :update_current_school, if: :employment_status_changed?) }

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
      bank_sort_code { 123456 }
      bank_account_number { 12345678 }
    end

    trait :eligible_but_unsubmittable do
      eligible_and_submittable
      email_address { nil }
    end
  end
end
