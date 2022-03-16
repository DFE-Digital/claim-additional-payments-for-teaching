FactoryBot.define do
  factory :school_workforce_census do
    trait :early_career_payments_matched do
      teacher_reference_number { 9855512 }
      subject_1 { "Mathematics / Mathematical Development (Early Years)" }
      subject_2 { "Statistics" }
    end

    trait :early_career_payments_unmatched do
      teacher_reference_number { 9855512 }
      subject_1 { "Problem Solving, Reasoning and Numeracy" }
      subject_2 { "Design and Technology - Electronics" }
    end

    trait :student_loans_matched do
      teacher_reference_number { 2109438 }
      subject_1 { "Science" }
      subject_2 { "Biology / Botany / Zoology / Ecology" }
      subject_3 { "Computer Science" }
    end

    trait :student_loans_unmatched do
      teacher_reference_number { 2109438 }
      subject_1 { "Other Mathematical Subject" }
      subject_2 { "Design and Technology - Electronics" }
    end
  end
end
