require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::ClaimSchoolForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  before { create(:journey_configuration, :student_loans) }

  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        taught_eligible_subjects: true,
        biology_taught: true,
        physics_taught: true,
        chemistry_taught: true,
        computing_taught: true,
        languages_taught: true,
        employment_status: :claim_school,
        current_school_id: existing_claim_school_id,
        claim_school_id: existing_claim_school_id
      }
    )
  end

  let(:existing_claim_school_id) { nil }

  let(:slug) { "claim-school" }

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: journey,
      params: params
    )
  end

  describe "#save" do
    context "claim_school_id submitted" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {possible_claim_school_id: school.id}}) }
      let(:school) { create(:school, :eligible_for_journey, journey: journey) }

      context "claim eligibility didn't have claim_school" do
        it "updates the claim_school on claim eligibility" do
          expect(form.save).to be true

          expect(journey_session.reload.answers.possible_claim_school_id).to eq school.id
        end
      end
    end

    context "when the school has changed" do
      let(:school) { create(:school, :student_loans_eligible) }
      let(:existing_claim_school_id) { school.id }
      let(:new_school) { create(:school, :student_loans_eligible) }

      let(:params) do
        ActionController::Parameters.new(
          {
            claim: {
              possible_claim_school_id: new_school.id
            }
          }
        )
      end

      it "resets the dependent answers" do
        expect { expect(form.save).to eq true }.to(
          change { journey_session.reload.answers.possible_claim_school_id }
          .from(nil).to(new_school.id)
          .and(
            change { journey_session.reload.answers.taught_eligible_subjects }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.biology_taught }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.physics_taught }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.chemistry_taught }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.computing_taught }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.languages_taught }
            .from(true).to(nil)
          ).and(
            change { journey_session.reload.answers.employment_status }
            .from("claim_school").to(nil)
          ).and(
            change { journey_session.reload.answers.current_school_id }
            .from(school.id).to(nil)
          )
        )
      end
    end

    context "when the claim school has not changed" do
      let(:school) { create(:school, :student_loans_eligible) }
      let(:existing_claim_school_id) { school.id }

      let(:params) do
        ActionController::Parameters.new(
          {
            claim: {
              possible_claim_school_id: existing_claim_school_id
            }
          }
        )
      end

      it "doesn't reset the dependent answers" do
        expect { expect(form.save).to eq true }.to(
          not_change { journey_session.reload.answers.claim_school_id }
          .and(
            not_change { journey_session.reload.answers.taught_eligible_subjects }
          ).and(
            not_change { journey_session.reload.answers.biology_taught }
          ).and(
            not_change { journey_session.reload.answers.physics_taught }
          ).and(
            not_change { journey_session.reload.answers.chemistry_taught }
          ).and(
            not_change { journey_session.reload.answers.computing_taught }
          ).and(
            not_change { journey_session.reload.answers.languages_taught }
          ).and(
            not_change { journey_session.reload.answers.employment_status }
          ).and(
            not_change { journey_session.reload.answers.current_school_id }
          )
        )
      end
    end
  end
end
