FactoryBot.define do
  factory :dfe_signin_user, class: "DfeSignIn::User" do
    dfe_sign_in_id { SecureRandom.uuid }
    given_name { "Jo" }
    family_name { "Bloggs" }
    email { "jo.bloggs@education.gov.uk" }
    organisation_name { "Department for Education" }

    trait :without_data do
      given_name { nil }
      family_name { nil }
      email { nil }
      organisation_name { nil }
    end
  end
end
