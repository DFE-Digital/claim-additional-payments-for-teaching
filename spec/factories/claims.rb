FactoryBot.define do
  sequence(:email_address) { |n| "person#{n}@example.com" }
  sequence(:teacher_reference_number, 1000000) { |n| n }
  sequence(:national_insurance_number, 100000) { |n| "QQ#{n}C" }

  factory :claim do
    transient do
      policy { StudentLoans }
      eligibility_factory { "#{policy.to_s.underscore}_eligibility".to_sym }
    end

    after(:build) do |claim, evaluator|
      claim.eligibility = build(*evaluator.eligibility_factory) unless claim.eligibility
    end

    trait :submittable do
      verified

      first_name { "Jo" }
      surname { "Bloggs" }
      address_line_1 { "1 Test Road" }
      postcode { "AB1 2CD" }
      date_of_birth { 20.years.ago.to_date }
      teacher_reference_number { generate(:teacher_reference_number) }
      national_insurance_number { generate(:national_insurance_number) }
      has_student_loan { true }
      student_loan_country { :england }
      student_loan_courses { :one_course }
      student_loan_start_date { StudentLoan::BEFORE_1_SEPT_2012 }
      student_loan_plan { StudentLoan::PLAN_1 }
      email_address { generate(:email_address) }
      banking_name { "Jo Bloggs" }
      bank_sort_code { rand(100000..999999) }
      bank_account_number { rand(10000000..99999999) }
      payroll_gender { :female }

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :eligible] }
    end

    trait :submitted do
      submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end

    trait :verified do
      govuk_verify_fields { %w[first_name surname address_line_1 postcode date_of_birth payroll_gender] }
      verify_response { {"scenario" => "IDENTITY_VERIFIED", "pid" => "123", "levelOfAssurance" => "LEVEL_2", "attributes" => {}} }
    end

    trait :unverified do
      submitted

      govuk_verify_fields { [] }
      verify_response { nil }
    end

    trait :approved do
      submitted
      association(:decision, factory: [:decision, :approved], strategy: :build)
    end

    trait :rejected do
      submitted
      association(:decision, factory: [:decision, :rejected], strategy: :build)
    end

    trait :ineligible do
      submittable

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :ineligible] }
    end
  end
end
