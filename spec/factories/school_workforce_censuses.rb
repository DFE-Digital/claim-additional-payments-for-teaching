FactoryBot.define do
  factory :school_workforce_census do
    trait :early_career_payments_matched do
      teacher_reference_number { 9855512 }
      subject_description_sfr { "Mathematics" }
    end

    trait :early_career_payments_unmatched do
      teacher_reference_number { 9855512 }
      subject_description_sfr { "Problem Solving, Reasoning and Numeracy" }
    end

    trait :levelling_up_premium_payments_matched do
      teacher_reference_number { 1560179 }
      subject_description_sfr { "ICT" }
    end

    trait :levelling_up_premium_payments_unmatched do
      teacher_reference_number { 1560179 }
      subject_description_sfr { "Problem Solving, Reasoning and Numeracy" }
    end

    trait :student_loans_matched do
      teacher_reference_number { 2109438 }
      subject_description_sfr { "Biology" }
    end

    trait :student_loans_matched_languages_only do
      teacher_reference_number { 3403431 }
      subject_description_sfr { "French" }
    end

    trait :student_loans_unmatched do
      teacher_reference_number { 2109438 }
      subject_description_sfr { "Other Mathematical Subject" }
    end
  end
end
