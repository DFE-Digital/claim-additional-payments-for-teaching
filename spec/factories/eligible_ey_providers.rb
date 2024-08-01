FactoryBot.define do
  factory :eligible_ey_provider do
    association :local_authority

    nursery_name { Faker::Company.name }
    urn { rand(10_000_000..99_999_999) }
    nursery_address { Faker::Address.full_address }
    primary_key_contact_email_address { Faker::Internet.email }
    secondary_contact_email_address { [Faker::Internet.email, nil].sample }
  end
end
