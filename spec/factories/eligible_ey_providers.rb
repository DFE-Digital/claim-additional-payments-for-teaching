FactoryBot.define do
  factory :eligible_ey_provider do
    association :local_authority

    file_upload {
      FileUpload.latest_version_for(EligibleEyProvider).first ||
        create(:file_upload, target_data_model: EligibleEyProvider.to_s)
    }

    nursery_name { Faker::Company.name }
    urn { rand(10_000_000..99_999_999) }
    nursery_address { Faker::Address.full_address }
    primary_key_contact_email_address { Faker::Internet.email }

    trait :with_sometimes_nil_secondary_contact_email_address do
      secondary_contact_email_address { [Faker::Internet.email, nil].sample }
    end

    trait :with_secondary_contact_email_address do
      secondary_contact_email_address { Faker::Internet.email }
    end
  end
end
