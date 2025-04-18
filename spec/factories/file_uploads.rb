FactoryBot.define do
  factory :file_upload do
    association :uploaded_by, factory: :dfe_signin_user

    target_data_model { nil }
    academic_year { nil }
    completed_processing_at { Time.zone.now }

    transient do
      row_count { 1 }
      row do
        []
      end
    end

    trait :school_workforce_census_upload do
      transient do
        row do
          [
            "1234567",
            "123456",
            "",
            1,
            "",
            "",
            ""
          ]
        end
      end
    end

    body do
      string = ""

      row_count.times do
        string << (row.join(",") + "\n")
      end

      string.presence
    end

    trait :not_completed_processing do
      completed_processing_at { nil }
    end
  end
end
