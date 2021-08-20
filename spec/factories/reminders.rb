FactoryBot.define do
  factory :reminder do
    full_name { Faker::Name.name }
    email_address { Faker::Internet.email }
  end
end
