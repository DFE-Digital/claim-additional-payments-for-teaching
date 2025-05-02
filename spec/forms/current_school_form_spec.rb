require "rails_helper"

RSpec.describe CurrentSchoolForm do
  shared_examples "current_school_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :targeted_retention_incentive_payments)
    }

    let(:journey_session) { create(:"#{journey::I18N_NAMESPACE}_session") }

    let(:slug) { "current-school" }

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

        context "exclude closed schools" do
          it "returns a list of schools" do
            schools = [create(:school), create(:school)]
            allow(School).to receive_message_chain(:open, :search).with("Some school name").and_return(schools)

            expect(form.schools).to eq schools
          end
        end
      end
    end

    describe "#current_school_name" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      context "claim eligibility DOES NOT have a current school" do
        it "returns nil" do
          expect(form.current_school_name).to be_nil
        end
      end

      context "answers DOES have a current school" do
        let(:school) { create(:school, :eligible_for_journey, journey: journey) }

        let(:journey_session) do
          create(
            :"#{journey::I18N_NAMESPACE}_session",
            answers: {current_school_id: school.id}
          )
        end

        it "returns school name" do
          expect(form.current_school_name).to eq school.name
        end
      end
    end

    describe "#save" do
      context "current_school_id submitted" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {current_school_id: school.id}}) }
        let(:school) { create(:school, :eligible_for_journey, journey: journey) }

        it "updates the journey_session" do
          expect { form.save }.to change { journey_session.reload.answers.current_school_id }.to(school.id)
        end

        context "submitted current_school_id is closed - super edge case school closed after loading form" do
          let(:school) { create(:school, :eligible_for_journey, :closed, journey: journey) }

          it "does not save and adds error to form" do
            expect(form.save).to be false
            expect(form.errors[:current_school_id]).to eq ["The selected school is closed"]
          end
        end

        context "submitted current_school_id doesn't exist - form manipulated" do
          let(:school) { double(id: "99999999999") }

          it "does not save and adds error to form" do
            expect(form.save).to be false
            expect(form.errors[:current_school_id]).to eq ["School not found"]
          end
        end
      end

      context "current_school_id missing" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {current_school_id: ""}}) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:current_school_id]).to eq ["Select the school you teach at"]
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
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "current_school_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples "current_school_form", Journeys::TargetedRetentionIncentivePayments
  end
end
