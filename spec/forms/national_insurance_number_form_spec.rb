require "rails_helper"

RSpec.describe NationalInsuranceNumberForm do
  let(:journey_session) do
    build(:further_education_payments_session)
  end

  let(:form) do
    described_class.new(
      journey: journey_session.journey_class,
      journey_session: journey_session,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  context "#save" do
    context "with a valid, poorly formatted NINO" do
      let(:params) do
        {
          national_insurance_number: "aB1 23456 c"
        }
      end

      it "normalises and saves the NINO" do
        expect { form.save }.to(
          change { journey_session.answers.national_insurance_number }
          .from(nil).to("AB123456C")
        )
      end
    end

    context "with a blank NINO" do
      let(:params) do
        {
          national_insurance_number: ""
        }
      end

      it "is invalid" do
        expect(form).not_to be_valid

        expect(
          form.errors[:national_insurance_number]
        ).to include("Enter a National Insurance number in the correct format")
      end
    end

    context "with an invalid NINO" do
      let(:params) do
        {
          national_insurance_number: "invalidNINO"
        }
      end

      it "is invalid" do
        expect(form).not_to be_valid

        expect(
          form.errors[:national_insurance_number]
        ).to include("Enter a National Insurance number in the correct format")
      end
    end
  end
end
