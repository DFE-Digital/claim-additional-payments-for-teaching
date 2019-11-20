FactoryBot.define do
  factory :claim do
    transient do
      policy { StudentLoans }
      eligibility_factory { "#{policy.to_s.underscore}_eligibility".to_sym }
    end

    after(:build) do |claim, evaluator|
      claim.eligibility = build(*evaluator.eligibility_factory) unless claim.eligibility
    end

    trait :submittable do
      first_name { "Jo" }
      surname { "Bloggs" }
      address_line_1 { "1 Test Road" }
      postcode { "AB1 2CD" }
      date_of_birth { 20.years.ago.to_date }
      teacher_reference_number { "1234567" }
      national_insurance_number { "QQ123456C" }
      has_student_loan { true }
      student_loan_country { :england }
      student_loan_courses { :one_course }
      student_loan_start_date { StudentLoan::BEFORE_1_SEPT_2012 }
      student_loan_plan { StudentLoan::PLAN_1 }
      email_address { "test@email.com" }
      banking_name { "Jo Bloggs" }
      bank_sort_code { 123456 }
      bank_account_number { 12345678 }
      payroll_gender { :female }

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :eligible] }
    end

    trait :submitted do
      submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end

    trait :approved do
      submitted
      association(:check, factory: [:check, :approved], strategy: :build)
    end

    trait :rejected do
      submitted
      association(:check, factory: [:check, :rejected], strategy: :build)
    end

    trait :ineligible do
      submittable

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :ineligible] }
    end
  end
end
