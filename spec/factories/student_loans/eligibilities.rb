# frozen_string_literal: true

FactoryBot.define do
  factory :student_loans_eligibility, class: "Policies::StudentLoans::Eligibility" do
    trait :eligible do
      association :current_school, factory: [:school, :student_loans_eligible]
      qts_award_year { :on_or_after_cut_off_date }
      employment_status { :claim_school }
      claim_school { current_school }
      physics_taught { true }
      had_leadership_position { true }
      mostly_performed_leadership_duties { false }
      award_amount { 1000 }
      teacher_reference_number { generate(:teacher_reference_number) }
    end

    trait :ineligible do
      eligible
      mostly_performed_leadership_duties { true }
    end
  end
end
