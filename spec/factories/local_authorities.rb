FactoryBot.define do
  factory :local_authority do
    sequence(:code) { |n| 1000 + n }
    name { "York" }
  end
end
