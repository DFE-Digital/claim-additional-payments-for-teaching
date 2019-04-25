FactoryBot.define do
  factory :local_authority do
    sequence(:code)
    name { "York" }
  end
end
