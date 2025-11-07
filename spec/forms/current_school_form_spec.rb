require "rails_helper"

RSpec.describe CurrentSchoolForm do
  shared_examples "current_school_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :targeted_retention_incentive_payments)
    }

    let(:journey_session) { create(:"#{journey.i18n_namespace}_session") }

    let(:slug) { "current-school" }

    subject(:form) do
      described_class.new(
        journey_session: journey_session,
        journey: journey,
        params: params
      )
    end

    describe "#save" do
      context "possible_school_id submitted" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {possible_school_id: school.id}}) }
        let(:school) { create(:school, :eligible_for_journey, journey: journey) }

        it "updates the journey_session" do
          expect { form.save }.to change { journey_session.reload.answers.possible_school_id }.to(school.id)
        end

        context "submitted possible_school_id is closed - super edge case school closed after loading form" do
          let(:school) { create(:school, :eligible_for_journey, :closed, journey: journey) }

          it "does not save and adds error to form" do
            expect(form.save).to be false
            expect(form.errors[:possible_school_id]).to eq ["The selected school is closed"]
          end
        end

        context "submitted possible_school_id doesn't exist - form manipulated" do
          let(:school) { double(id: "99999999999") }

          it "does not save and adds error to form" do
            expect(form.save).to be false
            expect(form.errors[:possible_school_id]).to eq ["School not found"]
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "current_school_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples "current_school_form", Journeys::TargetedRetentionIncentivePayments
  end
end
