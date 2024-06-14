require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SelectClaimSchoolForm, type: :model do
  before do
    create(
      :journey_configuration,
      :student_loans,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
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
          current_school_id: school.id,
          claim_school_id: school.id
        }
      )
    end
    let(:params) { ActionController::Parameters.new }
    let(:form) do
      described_class.new(
        journey:,
        journey_session:,
        params:
      )
    end
    let!(:school) { create(:school, :eligible_for_journey, journey:) }

    context "when choosing a school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            claim_school_id: school.id
          }
        })
      end

      it "updates the claim with the correct school attributes" do
        save

        expect(journey_session.reload.answers.claim_school_id).to eq(school.id)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to(
          change { journey_session.reload.answers.claim_school_somewhere_else }.to(false)
        )
      end

      it "doesnt reset depenent answers" do
        expect { save }.to(
          not_change { journey_session.reload.answers.taught_eligible_subjects }
          .and(
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

    context "with an existing school association and wants to change school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            claim_school_id: nil
          }
        })
      end

      it "resets the school association" do
        expect { save }.to change { journey_session.reload.answers.claim_school_id }.to(nil)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to(
          change { journey_session.reload.answers.claim_school_somewhere_else }.to(true)
        )
      end

      it "resets the dependent answers" do
        expect { form.save }.to(
          change { journey_session.reload.answers.taught_eligible_subjects }
          .from(true).to(nil)
          .and(
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
  end
end
