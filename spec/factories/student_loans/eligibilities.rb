# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_eligibility, class: "StudentLoans::Eligibility" do
    trait :eligible do
      employments { [build(:student_loans_employment, :eligible)] }

      qts_award_year { "2013_2014" }
      employment_status { :different_school }
      current_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      had_leadership_position { true }
      mostly_performed_leadership_duties { false }
    end

    trait :ineligible do
      eligible
      employment_status { :no_school }
    end
  end
end
