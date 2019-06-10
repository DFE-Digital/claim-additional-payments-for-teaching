FactoryBot.define do
  factory :local_authority do
    sequence(:code) { |n| 1000 + n }
    name { "Test LA" }

    initialize_with { LocalAuthority.find_or_create_by(code: code) }
  end
end
