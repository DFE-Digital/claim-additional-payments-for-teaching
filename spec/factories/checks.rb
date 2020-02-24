FactoryBot.define do
  factory :check do
    name { Admin::ChecksController::CHECKS_SEQUENCE.sample }
    association :created_by, factory: :dfe_signin_user
    association :claim
  end
end
