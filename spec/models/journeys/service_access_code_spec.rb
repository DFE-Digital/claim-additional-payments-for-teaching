require "rails_helper"

RSpec.describe Journeys::ServiceAccessCode, type: :model do
  describe "scopes" do
    describe ".used" do
      it "returns access codes marked as used" do
        used_code = create(:service_access_code, used: true)
        unused_code = create(:service_access_code, used: false)

        expect(described_class.used).to include(used_code)
        expect(described_class.used).not_to include(unused_code)
      end
    end

    describe ".unused" do
      it "returns access codes not marked as used" do
        used_code = create(:service_access_code, used: true)
        unused_code = create(:service_access_code, used: false)

        expect(described_class.unused).not_to include(used_code)
        expect(described_class.unused).to include(unused_code)
      end
    end
  end

  describe "#mark_as_used!" do
    it "marks the access code as used" do
      code = create(:service_access_code)

      expect { code.mark_as_used! }.to(
        change { code.reload.used }.from(false).to(true)
      )
    end
  end

  describe "claim submission with service access code" do
    it "marks the service access code as used when a claim is submitted" do
      service_access_code = create(
        :service_access_code,
        journey: Journeys::FurtherEducationPayments
      )

      answers = attributes_for(
        :further_education_payments_answers,
        :submittable,
        logged_in_with_onelogin: true,
        onelogin_idv_first_name: "John",
        onelogin_idv_last_name: "Doe",
        onelogin_idv_full_name: "John Doe",
        onelogin_idv_date_of_birth: Date.new(1970, 1, 1)
      ).merge(service_access_code: service_access_code.code)

      journey_session = create(
        :further_education_payments_session,
        answers: answers
      )

      form = Journeys::FurtherEducationPayments::ClaimSubmissionForm.new(
        journey_session: journey_session
      )

      expect(form.save).to be true

      expect(service_access_code.reload.used?).to be true
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

        service_access_code = create(
          :service_access_code,
          journey: journey,
          used: true
        )

        code = service_access_code.code

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
