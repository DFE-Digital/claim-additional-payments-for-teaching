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

  describe "#schools" do
    context "new form" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      it "returns nil" do
        expect(form.schools).to be_nil
      end
    end

    context "searching for a school" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Some school name"}) }

      it "returns a list of schools" do
        schools = [create(:school), create(:school)]
        allow(School).to receive(:search).with("Some school name").and_return(schools)

        expect(form.schools).to eq schools
      end
    end
  end

  describe "#claim_school_name" do
    let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

    context "when answers DOES NOT have a claim school" do
      it "returns nil" do
        expect(form.claim_school_name).to be_nil
      end
    end

    context "when answers DOES have a claim school" do
      let(:school) { create(:school, :eligible_for_journey, journey: journey) }

      let(:existing_claim_school_id) { school.id }

      it "returns school name" do
        expect(form.claim_school_name).to eq school.name
      end
    end
  end

  describe "#save" do
    context "claim_school_id submitted" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {claim_school_id: school.id}}) }

      let(:school) { create(:school, :eligible_for_journey, journey: journey) }

      context "claim eligibility didn't have claim_school" do
        it "updates the claim_school on claim eligibility" do
          expect(form.save).to be true

          expect(journey_session.reload.answers.claim_school_id).to eq school.id
        end
      end

      context "claim eligibility already had a claim_school" do
        let(:previous_school) { create(:school, :eligible_for_journey, journey: journey) }

        let(:existing_claim_school_id) { previous_school.id }

        it "updates the claim_school on claim eligibility" do
          expect(form.save).to be true

          expect(journey_session.reload.answers.claim_school_id).to eq school.id
        end
      end

      context "submitted claim_school_id doesn't exist - form manipulated" do
        let(:school) { double(id: "99999999999") }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:claim_school_id]).to eq ["School not found"]
        end
      end
    end

    context "claim_school_id missing" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {claim_school_id: ""}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:claim_school_id]).to eq ["Select a school from the list or search again for a different school"]
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
              claim_school_id: new_school.id
            }
          }
        )
      end

      it "resets the dependent answers" do
        expect { expect(form.save).to eq true }.to(
          change { journey_session.reload.answers.claim_school_id }
          .from(school.id).to(new_school.id)
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
              claim_school_id: existing_claim_school_id
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

  describe "no_search_results?" do
    context "no schools found" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Some school name"}) }

      it "returns true" do
        allow(School).to receive(:search).with("Some school name").and_return([])

        expect(form.no_search_results?).to be true
      end
    end

    context "school_search less than 3 characters" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Ab"}) }

      it "returns false" do
        expect(form.no_search_results?).to be false
      end
    end
  end

  describe "show_multiple_schools_content?" do
    context "additional-school params set" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, additional_school: true}) }

      it "returns false" do
        expect(form.show_multiple_schools_content?).to be false
      end
    end

    context "additional-school params NOT set" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      it "returns true" do
        expect(form.show_multiple_schools_content?).to be true
      end
    end
  end
end
