require "rails_helper"

RSpec.describe Debug::StriBypassJob do
  let(:journey_session) do
    create(:school_targeted_retention_incentive_payments_session)
  end

  describe "#perform" do
    context "when NI given" do
      it "sets NI number" do
        expect(journey_session.answers.trs_data).to be_nil

        subject.perform(
          journey_session:,
          has_national_insurance_number: true,
          national_insurance_number: "AB123456C"
        )

        expect(journey_session.reload.answers.trs_data["nationalInsuranceNumber"]).to eql("AB123456C")
      end
    end

    context "when NI not given" do
      it "does not set NI number" do
        expect(journey_session.answers.trs_data).to be_nil

        subject.perform(
          journey_session:,
          has_national_insurance_number: false,
          national_insurance_number: "AB123456C"
        )

        expect(journey_session.reload.answers.trs_data["nationalInsuranceNumber"]).to be_blank
      end
    end
  end
end
