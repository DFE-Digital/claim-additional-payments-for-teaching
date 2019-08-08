# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_eligibility, class: "StudentLoans::Eligibility" do
    trait :eligible do
      qts_award_year { "2013_2014" }
      claim_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      employment_status { :claim_school }
      current_school { claim_school }
      physics_taught { true }
      mostly_teaching_eligible_subjects { true }
    end
  end
end
