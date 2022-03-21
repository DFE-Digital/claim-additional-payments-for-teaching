FactoryBot.define do
  factory :teachers_pensions_service do
    trait :early_career_payments_matched_first do
      teacher_reference_number { 1334425 }
      la_urn { 370 } # actually is the local_authority.code
      school_urn { 8091 } # actually is the school.establishment_number
      start_date { DateTime.new(2021, 12, 1, 16, 0, 0) }
    end

    trait :early_career_payments_matched_second do
      teacher_reference_number { 1334425 }
      la_urn { 370 }
      school_urn { 8091 }
      start_date { DateTime.new(2022, 1, 1, 16, 0, 0) }
    end

    trait :early_career_payments_matched_third do
      teacher_reference_number { 1334425 }
      la_urn { 370 }
      school_urn { 8091 }
      start_date { DateTime.new(2022, 2, 1, 16, 0, 0) }
    end

    trait :early_career_payments_unmatched_unmatched_jan_2022 do
      teacher_reference_number { 1334425 }
      la_urn { 383 }
      school_urn { 4026 }
      start_date { DateTime.new(2022, 1, 1, 16, 0, 0) }
    end

    trait :early_career_payments_unmatched_december_2021 do
      teacher_reference_number { 1334425 }
      la_urn { 383 }
      school_urn { 4026 }
      start_date { DateTime.new(2021, 12, 1, 16, 0, 0) }
    end
  end
end
