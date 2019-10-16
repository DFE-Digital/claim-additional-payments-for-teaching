FactoryBot.define do
  factory :payment do
    association(:claim, factory: [:claim, :approved])
    association(:payroll_run, factory: :payroll_run)

    award_amount { claim.award_amount }
  end
end
