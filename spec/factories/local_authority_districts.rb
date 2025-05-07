FactoryBot.define do
  factory :local_authority_district do
    name { Faker::Address.community }
    sequence(:code, 1000) { |n| "E0000#{n}" }

    initialize_with { LocalAuthorityDistrict.find_or_create_by(code: code) }
  end
end
