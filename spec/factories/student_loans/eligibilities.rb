# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_eligibility, class: "StudentLoans::Eligibility" do
    trait :submittable do
      qts_award_year { "2013_2014" }
    end
  end
end
