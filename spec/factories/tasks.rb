FactoryBot.define do
  factory :task do
    name { ClaimCheckingTasks.new(claim).applicable_task_names.sample }
    passed { true }
    association :created_by, factory: :dfe_signin_user
    association :claim
  end
end
