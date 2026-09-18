require "rails_helper"

RSpec.describe Debug::FetchNinoBypassJob do
  describe "#perform" do
    let(:journey_session) do
      create(:school_targeted_retention_incentive_payments_session)
    end

    context "when user has NI number" do
      it "stores NI number with completed timestamp" do
        expect {
          subject.perform(journey_session:, has_national_insurance_number: true, national_insurance_number: "AB123456C")
        }.to change { journey_session.reload.answers.trs_national_insurance_number }.from(nil).to("AB123456C")
          .and change { journey_session.reload.answers.trs_national_insurance_number_completed_at }.from(nil)
      end
    end

    context "when user does not have NI number" do
      it "stores completed timestamp only" do
        expect {
          subject.perform(journey_session:, has_national_insurance_number: false, national_insurance_number: "AB123456C")
        }.to not_change { journey_session.reload.answers.trs_national_insurance_number }
          .and change { journey_session.reload.answers.trs_national_insurance_number_completed_at }.from(nil)
      end
    end
  end
end
