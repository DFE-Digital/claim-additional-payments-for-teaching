require "rails_helper"

RSpec.describe Journeys::ServiceAccessCode, type: :model do
  describe ".unused" do
    it "returns the used service access codes" do
      unused_service_access_code = create(:service_access_code)

      used_service_access_code = create(:service_access_code)

      journey_session = create(
        :further_education_payments_session,
        answers: {
          service_access_code: used_service_access_code.code
        }
      )

      create(:claim, journey_session: journey_session)

      expect(described_class.unused).to eq([unused_service_access_code])
    end
  end

  describe "#permits_access?" do
    context "when the code is blank" do
      it "returns false" do
        journey = Journeys::FurtherEducationPayments

        code = ""

        expect(
          described_class.permits_access?(code: code, journey: journey)
        ).to be false
      end
    end

    context "when the code is for a different journey" do
      it "returns false" do
        code = create(
          :service_access_code,
          journey: Journeys::FurtherEducationPayments
        ).code

        journey = Journeys::GetATeacherRelocationPayment

        expect(
          described_class.permits_access?(code: code, journey: journey)
        ).to be false
      end
    end

    context "when the code is used" do
      it "returns false" do
        journey = Journeys::FurtherEducationPayments

        service_access_code = create(:service_access_code, journey: journey)

        code = service_access_code.code

        journey_session = create(
          :further_education_payments_session,
          answers: {
            service_access_code: service_access_code.code
          }
        )

        create(:claim, journey_session: journey_session)

        expect(
          described_class.permits_access?(code: code, journey: journey)
        ).to be false
      end
    end

    context "when the code is for the correct journey and unused" do
      it "returns true" do
        journey = Journeys::FurtherEducationPayments

        code = create(:service_access_code, journey: journey).code

        expect(
          described_class.permits_access?(code: code, journey: journey)
        ).to be true
      end
    end
  end
end
