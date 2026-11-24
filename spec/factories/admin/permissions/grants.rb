FactoryBot.define do
  factory :admin_permissions_grant, class: "Admin::Permissions::Grant" do
    association :user, factory: :dfe_signin_user
    permission { Admin::Permissions::ALL.first }
    granted_at { Time.zone.now }

    trait :revoked do
      revoked_at { Time.zone.now }
    end
  end
end
