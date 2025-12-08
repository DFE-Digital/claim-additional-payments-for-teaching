require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::CheckYourAnswersForm do
  before do
    create(:journey_configuration, :further_education_payments, current_academic_year:)
  end

  let(:current_academic_year) { AcademicYear.new(2025) }
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:school) { create(:school, :further_education, :fe_eligible) }

  let(:answers_params) do
    {
      academic_year: current_academic_year,
      identity_confirmed_with_onelogin: true,
      logged_in_with_onelogin: true,
      onelogin_idv_first_name: "John",
      onelogin_idv_last_name: "Doe",
      onelogin_idv_full_name: "John Doe",
      onelogin_idv_date_of_birth: Date.new(1970, 1, 1),
      first_name: "John",
      surname: "Doe",
      date_of_birth: Date.new(1970, 1, 1)
    }
  end

  let(:answers) {
    build(
      :further_education_payments_answers,
      :submittable,
      :with_onelogin_credentials,
      **answers_params
    )
  }

  let(:journey_session) { create(:further_education_payments_session, answers: answers) }
  let(:form) do
    described_class.new(
      journey_session: journey_session,
      params: ActionController::Parameters.new(
        claim: {
          claimant_declaration: "1"
        }
      ),
      session: {},
      journey: Journeys::FurtherEducationPayments
    )
  end

  describe "#save" do
    subject { form.save }

    it "saves all answers into the Eligibility model" do
      subject
      claim = form.claim
      eligibility = form.claim.eligibility

      expect(claim.policy).to eql(Policies::FurtherEducationPayments)

      expect(claim.identity_confirmed_with_onelogin).to eq(answers.identity_confirmed_with_onelogin)
      expect(claim.logged_in_with_onelogin).to eq(answers.logged_in_with_onelogin)
      expect(claim.onelogin_credentials).to eq(answers.onelogin_credentials)
      expect(claim.onelogin_user_info).to eq(answers.onelogin_user_info)
      expect(claim.started_at).to eql(journey_session.created_at)

      expect(claim.onelogin_uid).to eql(answers.onelogin_uid)
      expect(claim.onelogin_auth_at).to eql(answers.onelogin_auth_at)
      expect(claim.onelogin_idv_at).to eql(answers.onelogin_idv_at)
      expect(claim.onelogin_idv_first_name).to eql(answers.onelogin_idv_first_name)
      expect(claim.onelogin_idv_last_name).to eql(answers.onelogin_idv_last_name)
      expect(claim.onelogin_idv_full_name).to eql(answers.onelogin_idv_full_name)
      expect(claim.onelogin_idv_date_of_birth).to eql(answers.onelogin_idv_date_of_birth)

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

    context "when in year 2 - further_education_teaching_start_year" do
      let(:previous_year_1_claim) do
        create(
          :claim,
          :further_education,
          :approved,
          academic_year: AcademicYear.new(2024),
          onelogin_uid: answers.onelogin_uid
        )
      end

      context "when a year 1 claim exists with a teaching start year of 2020" do
        before do
          previous_year_1_claim.eligibility.update!(
            further_education_teaching_start_year: "2020"
          )
        end

        it "flags the eligibility as a teaching start year mismatch" do
          subject
          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to be true
        end
      end

      context "when a year 1 claim exists with a teaching start year of 2021 (or above)" do
        before do
          previous_year_1_claim.eligibility.update!(
            further_education_teaching_start_year: "2021"
          )
        end

        it "DOES NOT flag the eligibility as a teaching start year mismatch" do
          subject
          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to be false
        end
      end
    end

    context "when in year 3 (or later) - further_education_teaching_start_year" do
      let(:current_academic_year) { AcademicYear.new(2026) }

      let(:previous_year_2_claim) do
        create(
          :claim,
          :further_education,
          :approved,
          academic_year: AcademicYear.new(2025),
          onelogin_uid: answers.onelogin_uid
        )
      end

      context "when a year 2 claim exists with a teaching start year of 2023 AND year 3 teaching start year is also 2023" do
        let(:answers_params) do
          super().merge(
            further_education_teaching_start_year: "2023"
          )
        end

        before do
          previous_year_2_claim.eligibility.update!(
            further_education_teaching_start_year: "2023"
          )
        end

        it "DOES NOT flag the eligibility as a teaching start year mismatch" do
          subject
          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to be false
        end
      end

      context "when a year 2 claim exists with a teaching start year of 2022 AND year 3 teaching start year is 2023" do
        let(:answers_params) do
          super().merge(
            further_education_teaching_start_year: "2023"
          )
        end

        before do
          previous_year_2_claim.eligibility.update!(
            further_education_teaching_start_year: "2022"
          )
        end

        it "flags the eligibility as a teaching start year mismatch" do
          subject
          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to be true
        end
      end

      context "where a year 1 claim exists with a teaching start year of 2021" do
        let(:answers_params) do
          super().merge(
            further_education_teaching_start_year: "2023"
          )
        end

        let(:previous_year_1_claim) do
          create(
            :claim,
            :further_education,
            :approved,
            academic_year: AcademicYear.new(2024),
            onelogin_uid: answers.onelogin_uid
          )
        end

        before do
          previous_year_1_claim.eligibility.update!(
            further_education_teaching_start_year: "2021"
          )
        end

        it "flags the eligibility as a teaching start year mismatch" do
          subject
          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to be true
        end
      end
    end

    context "when in year 2 - flagged_as_previously_start_year_matches_claim_false" do
      let(:previous_year_1_claim_approved) do
        create(
          :claim,
          :further_education,
          :approved,
          academic_year: AcademicYear.new(2024),
          onelogin_uid: answers.onelogin_uid
        )
      end

      let(:previous_year_1_claim_rejected) do
        create(
          :claim,
          :further_education,
          :rejected,
          academic_year: AcademicYear.new(2024),
          onelogin_uid: answers.onelogin_uid,
          eligibility_trait: :year_one_verified_teaching_start_year_false
        )
      end

      context "when a year 1 approved claim exists" do
        before do
          previous_year_1_claim_approved
        end

        it "DOES NOT flag as previously start year matches claim" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be false
        end
      end

      context "when a year 1 rejected claim exists with provider_verification_teaching_start_year_matches_claim false" do
        before do
          previous_year_1_claim_rejected
        end

        it "flags as previously the start year matches claim was false by provider" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be true
        end
      end

      context "when an approved and rejected claim exist in the same year" do
        before do
          previous_year_1_claim_approved
          previous_year_1_claim_rejected
        end

        it "ignore the rejected claim and DOES NOT flag" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be false
        end
      end
    end

    context "when in year 3 - flagged_as_previously_start_year_matches_claim_false" do
      let(:current_academic_year) { AcademicYear.new(2026) }

      let(:previous_year_2_claim_approved) do
        create(
          :claim,
          :further_education,
          :approved,
          academic_year: AcademicYear.new(2025),
          onelogin_uid: answers.onelogin_uid
        )
      end

      let(:previous_year_2_claim_rejected) do
        create(
          :claim,
          :further_education,
          :rejected,
          academic_year: AcademicYear.new(2025),
          onelogin_uid: answers.onelogin_uid,
          eligibility_attributes: {
            provider_verification_teaching_start_year_matches_claim: false
          }
        )
      end

      context "when a year 2 approved claim exists" do
        before do
          previous_year_2_claim_approved
        end

        it "DOES NOT flag as previously start year matches claim" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be false
        end
      end

      context "when a year 2 rejected claim exists with provider_verification_teaching_start_year_matches_claim false" do
        before do
          previous_year_2_claim_rejected
        end

        it "flags as previously the start year matches claim was false by provider" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be true
        end
      end

      context "when an approved and rejected claim exist in the same year" do
        before do
          previous_year_2_claim_approved
          previous_year_2_claim_rejected
        end

        it "ignore the rejected claim and DOES NOT flag" do
          subject

          eligibility = form.claim.eligibility

          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to be false
        end
      end
    end
  end
end
