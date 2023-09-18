FactoryBot.define do
  factory :task do
    name { ClaimCheckingTasks.new(claim).applicable_task_names.sample }
    passed { true }
    manual { true }
    association :created_by, factory: :dfe_signin_user
    association :claim, :submitted

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
    end

    trait :manual do
      manual { true }
    end

    trait :automated do
      manual { false }
    end
  end
end
