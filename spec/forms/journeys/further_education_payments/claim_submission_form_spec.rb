require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::ClaimSubmissionForm do
  before do
    create(:journey_configuration, :further_education_payments)
  end

  let(:journey) { Journeys::FurtherEducationPayments }
  let(:school) { create(:school, :further_education, :fe_eligible) }

  let(:answers) {
    build(
      :further_education_payments_answers,
      :submittable,
      :with_onelogin_credentials,
      identity_confirmed_with_onelogin: true,
      logged_in_with_onelogin: true
    )
  }

  let(:journey_session) { create(:further_education_payments_session, answers: answers) }
  let(:form) { described_class.new(journey_session: journey_session) }

  describe "#save" do
    subject { form.save }

    it "saves all answers into the Eligibility model" do
      subject
      claim = form.claim
      eligibility = form.claim.eligibility

      expect(claim.identity_confirmed_with_onelogin).to eq(answers.identity_confirmed_with_onelogin)
      expect(claim.logged_in_with_onelogin).to eq(answers.logged_in_with_onelogin)
      expect(claim.onelogin_credentials).to eq(answers.onelogin_credentials)
      expect(claim.onelogin_user_info).to eq(answers.onelogin_user_info)

      expect(eligibility.award_amount).to eq(answers.award_amount)
      expect(eligibility.teacher_reference_number).to eq(answers.teacher_reference_number)
      expect(eligibility.teaching_responsibilities).to eq(answers.teaching_responsibilities)
      expect(eligibility.provision_search).to eq(answers.provision_search)
      expect(eligibility.possible_school_id).to eq(answers.possible_school_id)
      expect(eligibility.school_id).to eq(answers.school_id)
      expect(eligibility.contract_type).to eq(answers.contract_type)
      expect(eligibility.fixed_term_full_year).to eq(answers.fixed_term_full_year)
      expect(eligibility.taught_at_least_one_term).to eq(answers.taught_at_least_one_term)
      expect(eligibility.teaching_hours_per_week).to eq(answers.teaching_hours_per_week)
      expect(eligibility.teaching_hours_per_week_next_term).to eq(answers.teaching_hours_per_week_next_term)
      expect(eligibility.further_education_teaching_start_year).to eq(answers.further_education_teaching_start_year)
      expect(eligibility.subjects_taught).to eq(answers.subjects_taught)
      expect(eligibility.building_construction_courses).to eq(answers.building_construction_courses)
      expect(eligibility.chemistry_courses).to eq(answers.chemistry_courses)
      expect(eligibility.computing_courses).to eq(answers.computing_courses)
      expect(eligibility.early_years_courses).to eq(answers.early_years_courses)
      expect(eligibility.engineering_manufacturing_courses).to eq(answers.engineering_manufacturing_courses)
      expect(eligibility.maths_courses).to eq(answers.maths_courses)
      expect(eligibility.physics_courses).to eq(answers.physics_courses)
      expect(eligibility.hours_teaching_eligible_subjects).to eq(answers.hours_teaching_eligible_subjects)
      expect(eligibility.teaching_qualification).to eq(answers.teaching_qualification)
      expect(eligibility.subject_to_formal_performance_action).to eq(answers.subject_to_formal_performance_action)
      expect(eligibility.subject_to_disciplinary_action).to eq(answers.subject_to_disciplinary_action)
      expect(eligibility.half_teaching_hours).to eq(answers.half_teaching_hours)
    end
  end
end
