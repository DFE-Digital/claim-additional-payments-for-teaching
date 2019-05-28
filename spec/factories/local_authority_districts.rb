FactoryBot.define do
  factory :local_authority_district do
    name { "Barnsley" }
    sequence(:code, 1000) { |n| "E0000#{n}" }
  end
end
