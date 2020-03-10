FactoryBot.define do
  factory :task do
    name { Admin::TasksController::TASKS_SEQUENCE.sample }
    association :created_by, factory: :dfe_signin_user
    association :claim
  end
end
