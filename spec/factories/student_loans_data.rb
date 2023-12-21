FactoryBot.define do
  factory :student_loans_data do
    claim_reference { Reference.new.to_s }
    nino { generate(:national_insurance_number) }
    full_name { Faker::Name.name }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    policy_name { EarlyCareerPayments }
    no_of_plans_currently_repaying { 1 }
    plan_type_of_deduction { 1 }
    amount { 150 }
  end
end
