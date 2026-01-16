FactoryBot.define do
  factory :dfe_signin_user, class: "DfeSignIn::User" do
    user_type { "admin" }
    dfe_sign_in_id { SecureRandom.uuid }
    given_name { "Aaron" }
    family_name { "Admin" }
    email { "aaron.admin@education.gov.uk" }
    organisation_name { "Department for Education" }

    trait :without_data do
      given_name { nil }
      family_name { nil }
      email { nil }
      organisation_name { nil }
    end

    trait :with_random_name do
      given_name { Faker::Name.first_name }
      family_name { Faker::Name.last_name }
    end

    trait :deleted do
      deleted_at { Time.zone.now }
    end

    trait :service_operator do
      role_codes { [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE] }
    end

    trait :support_agent do
      role_codes { [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE] }
    end

    trait :service_admin do
      role_codes do
        [
          DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
          DfeSignIn::User::SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE
        ]
      end
    end

    trait :provider do
      user_type { "provider" }
    end
  end
end
