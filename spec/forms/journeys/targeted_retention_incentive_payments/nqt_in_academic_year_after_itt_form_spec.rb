require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::NqtInAcademicYearAfterIttForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {}
    )
  end

  let(:params) do
    {}
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil).for(:nqt_in_academic_year_after_itt).with_message(
          "Select yes if you are currently teaching as a qualified teacher"
        )
      )
    end
  end

  describe "#save" do
    context "when invalid" do
      it "returns false and does not save the journey session" do
        expect { expect(form.save).to be(false) }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end

    context "when valid with true value" do
      let(:params) do
        {
          nqt_in_academic_year_after_itt: "true"
        }
      end

      it "updates the session with nqt_in_academic_year_after_itt value" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.nqt_in_academic_year_after_itt }
          .from(nil).to(true)
        )
      end

      it "does not set qualification" do
        form.save
        expect(journey_session.reload.answers.qualification).to be_nil
      end
    end

    context "when valid with false value (trainee teacher)" do
      let(:params) do
        {
          nqt_in_academic_year_after_itt: "false"
        }
      end

      it "updates the session with nqt_in_academic_year_after_itt value" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.nqt_in_academic_year_after_itt }
          .from(nil).to(false)
        )
      end

      it "sets qualification to postgraduate_itt via QualificationForm" do
        expect { form.save }.to change { journey_session.reload.answers.qualification }
          .from(nil).to("postgraduate_itt")
      end
    end
  end
end
