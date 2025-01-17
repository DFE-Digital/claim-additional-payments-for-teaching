require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::IttAcademicYearForm do
  before {
    create(:journey_configuration, :additional_payments)
  }

  let(:current_value) { nil }

  let(:qualification_details_check) { nil }

  let(:journey_session) do
    create(
      :additional_payments_session,
      answers: {
        qualification: "postgraduate_itt",
        itt_academic_year: current_value,
        eligible_itt_subject: "mathematics",
        qualifications_details_check: qualification_details_check
      }
    )
  end

  let(:slug) { "itt_year" }

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::AdditionalPaymentsForTeaching,
      params: params
    )
  end

  describe "#itt_academic_year" do
    let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

    context "claim eligibility DOES NOT have a current value" do
      it "returns nil" do
        expect(form.itt_academic_year).to be_nil
      end
    end

    context "claim eligibility DOES have a current value" do
      let(:current_value) { AcademicYear.new(4.years.ago.year) }

      it "returns the current value" do
        expect(form.itt_academic_year).to eq current_value
      end
    end
  end

  describe "#save" do
    context "itt_academic_year submitted" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {itt_academic_year: new_value}}) }

      context "when the itt_academic_year has not changed" do
        let(:current_value) { AcademicYear.new(4.years.ago.year).to_s }
        let(:new_value) { current_value }

        it "doesn't reset the eligible_itt_subject" do
          expect { expect(form.save).to be true }.to(
            not_change { journey_session.reload.answers.eligible_itt_subject }
          )
        end
      end

      context "when the the itt_academic year has changed" do
        let(:new_value) { AcademicYear.new(2.years.ago.year).to_s }

        context "when the eligible_itt_subject came from dqt" do
          let(:qualification_details_check) { true }

          it "does not reset the eligible_itt_subject" do
            expect { expect(form.save).to be true }.to(
              not_change { journey_session.reload.answers.eligible_itt_subject }
            )

            expect(journey_session.answers.itt_academic_year).to eq new_value
          end
        end

        context "when the eligible_itt_subject did not come from dqt" do
          it "resets the eligible_itt_subject" do
            expect { expect(form.save).to be true }.to(
              change { journey_session.reload.answers.eligible_itt_subject }
              .from("mathematics").to(nil)
            )

            expect(journey_session.answers.itt_academic_year).to eq new_value
          end
        end
      end
    end

    context "itt_academic_year missing" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {itt_academic_year: ""}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:itt_academic_year]).to eq ["Select the academic year you started your postgraduate ITT"]
      end
    end
  end

  describe "#qualification_is?" do
    let(:params) { ActionController::Parameters.new({slug: slug}) }

    it "returns true for a single argument match" do
      expect(form.qualification_is?(:postgraduate_itt)).to be true
    end

    it "returns false for a single argument miss" do
      expect(form.qualification_is?(:undergraduate_itt)).to be false
    end

    it "returns true for an argument match" do
      expect(form.qualification_is?(:undergraduate_itt, :postgraduate_itt, :other)).to be true
    end

    it "returns false for an argument miss" do
      expect(form.qualification_is?(:undergraduate_itt, :assessment_only, :other)).to be false
    end
  end
end
