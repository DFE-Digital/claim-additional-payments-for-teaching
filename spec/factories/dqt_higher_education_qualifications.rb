FactoryBot.define do
  factory :dqt_higher_education_qualification do
    teacher_reference_number { generate(:teacher_reference_number).to_s }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    national_insurance_number { nil }
    subject_code { Faker::Alphanumeric.alphanumeric(number: 4) }
    description { Faker::Lorem.sentence(word_count: 3) }
  end
end
