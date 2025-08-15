require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ClaimantPersonalDetailsForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::AlternativeIdv }

  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      first_name: "Edna",
      surname: "Krabappel",
      identity_confirmed_with_onelogin: false
    )
  end

  let(:journey_session) do
    create(
      :early_years_payment_provider_alternative_idv_session,
      answers: {
        claim_reference: claim.reference
      }
    )
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: journey,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    describe "claimant_date_of_birth" do
      context "when missing" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "",
            "claimant_date_of_birth(2i)": "",
            "claimant_date_of_birth(1i)": ""
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Enter Edna Krabappel’s date of birth"
          )
        end
      end

      context "when missing day" do
        let(:params) do
          {
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid day" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "32",
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Enter a date of birth in the correct format"
          )
        end
      end

      context "when missing month" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid month" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "13",
            "claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Enter a date of birth in the correct format"
          )
        end
      end

      context "when missing year" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "1"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid date" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "30",
            "claimant_date_of_birth(2i)": "2",
            "claimant_date_of_birth(1i)": "2021"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Enter a date of birth in the correct format"
          )
        end
      end

      context "when future" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "2086"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Date of birth must be in the past"
          )
        end
      end

      context "when a year with less than 4 digits" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "49"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Year must include 4 numbers"
          )
        end
      end

      context "when a year before 1900" do
        let(:params) do
          {
            "claimant_date_of_birth(3i)": "21",
            "claimant_date_of_birth(2i)": "1",
            "claimant_date_of_birth(1i)": "1899"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:claimant_date_of_birth]).to include(
            "Year must be after 1900"
          )
        end
      end
    end

    describe "claimant_national_insurance_number" do
      let(:params) do
        {}
      end

      it do
        is_expected.to(
          validate_presence_of(
            :claimant_national_insurance_number
          ).with_message("Enter a National Insurance number in the correct format")
        )
      end

      it do
        is_expected.to(
          allow_value("QQ123456C")
          .for(:claimant_national_insurance_number)
        )
      end

      it do
        is_expected.to(
          allow_value("QQ 34 56 78 C")
          .for(:claimant_national_insurance_number)
        )
      end

      it do
        is_expected.not_to(
          allow_value("12 34 56 78 C")
          .for(:claimant_national_insurance_number)
        )
      end

      it do
        is_expected.not_to(
          allow_value("QQ 11 56 78 DE")
          .for(:claimant_national_insurance_number)
        )
      end
    end

    describe "claimant_postcode" do
      let(:params) do
        {}
      end

      it do
        is_expected.to(
          validate_presence_of(:claimant_postcode)
            .with_message("Enter a real postcode, for example NE1 6EE")
        )
      end

      it do
        is_expected.not_to(
          allow_value("SW1A").for(:claimant_postcode)
            .with_message("Enter a postcode in the correct format")
        )
      end
    end

    describe "claimant_email" do
      let(:params) do
        {}
      end

      context "when missing" do
        it "is invalid" do
          form.claimant_email = ""
          expect(form).not_to be_valid
          expect(form.errors[:claimant_email]).to include(
            "Enter an email address"
          )
        end
      end

      context "when invalid format" do
        it "is invalid" do
          form.claimant_email = "invalid-email"
          expect(form).not_to be_valid
          expect(form.errors[:claimant_email]).to include(
            "Enter an email address in the correct format, like name@example.com"
          )
        end
      end

      context "when too long" do
        it "is invalid" do
          form.claimant_email = "a" * 120 + "@example.com"
          expect(form).not_to be_valid
          expect(form.errors[:claimant_email]).to include(
            "Email address must be 129 characters or less"
          )
        end
      end

      context "when valid format" do
        it "is valid for this field" do
          form.claimant_email = "test@example.com"
          expect(form.errors[:claimant_email]).to be_empty
        end
      end
    end

    describe "claimant_bank_details_match" do
      let(:params) do
        {}
      end

      it do
        is_expected.not_to(
          allow_value(nil).for(:claimant_bank_details_match)
        )
      end

      it do
        is_expected.to(
          allow_value(true).for(:claimant_bank_details_match)
        )
      end

      it do
        is_expected.to(
          allow_value(false).for(:claimant_bank_details_match)
        )
      end
    end
  end
end
