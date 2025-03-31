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

      after(:create) do |task, _evaluator|
        # When failing checks automatically, the `passed` attribute is saved as `nil`;
        # a validation would normally prevent it when saved in a default context instead.
        if !task.manual?
          task.passed = nil
          task.save!(context: :claim_verifier)
        end
      end
    end

    trait :manual do
      manual { true }
    end

    trait :automated do
      manual { false }
    end

    trait :claim_verifier_context do
      to_create { it.save!(context: :claim_verifier) }
    end
  end
end
