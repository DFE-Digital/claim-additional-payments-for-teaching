# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_eligibility, class: "StudentLoans::Eligibility" do
    trait :eligible do
      qts_award_year { "2013_2014" }
      currently_teaching { true }
      claim_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      employment_status { :different_school }
      current_school { claim_school }
      physics_taught { true }
      had_leadership_position { true }
      mostly_performed_leadership_duties { false }
      student_loan_repayment_amount { 1000 }
    end

    trait :ineligible do
      eligible
      mostly_performed_leadership_duties { true }
    end
  end
end
