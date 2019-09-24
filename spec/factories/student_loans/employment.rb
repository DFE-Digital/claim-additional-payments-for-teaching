# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_employment, class: "StudentLoans::Employment" do
    school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }

    trait :eligible do
      physics_taught { true }
      student_loan_repayment_amount { 1000 }
    end

    trait :ineligible do
      eligible
      mostly_performed_leadership_duties { true }
    end
  end
end
