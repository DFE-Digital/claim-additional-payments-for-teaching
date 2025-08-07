require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ClaimantPersonalDetailsForm, type: :model do
  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(
      :claim,
      :further_education,
      first_name: "Edna",
      surname: "Krabappel"
    )
  end

  let(:params) do
    {}
  end

  subject(:form) do
    described_class.new(
      claim: claim,
      user: user,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    describe "provider_verification_claimant_date_of_birth" do
      context "when missing" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "",
            "provider_verification_claimant_date_of_birth(2i)": "",
            "provider_verification_claimant_date_of_birth(1i)": ""
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Enter the applicant’s date of birth"
          )
        end
      end

      context "when missing day" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(2i)": "1",
            "provider_verification_claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid day" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "32",
            "provider_verification_claimant_date_of_birth(2i)": "1",
            "provider_verification_claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Enter the applicant’s date of birth in the correct format"
          )
        end
      end

      context "when missing month" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid month" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(2i)": "13",
            "provider_verification_claimant_date_of_birth(1i)": "1949"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Enter the applicant’s date of birth in the correct format"
          )
        end
      end

      context "when missing year" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(2i)": "1"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Date of birth must include a day, month and year in the correct " \
            "format, for example 01 01 1980"
          )
        end
      end

      context "when invalid date" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "30",
            "provider_verification_claimant_date_of_birth(2i)": "2",
            "provider_verification_claimant_date_of_birth(1i)": "2021"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Enter the applicant’s date of birth in the correct format"
          )
        end
      end

      context "when future" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(2i)": "1",
            "provider_verification_claimant_date_of_birth(1i)": "2086"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Date of birth must be in the past"
          )
        end
      end

      context "when a year with less than 4 digits" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(2i)": "1",
            "provider_verification_claimant_date_of_birth(1i)": "49"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Year must include 4 numbers"
          )
        end
      end

      context "when a year before 1900" do
        let(:params) do
          {
            "provider_verification_claimant_date_of_birth(3i)": "21",
            "provider_verification_claimant_date_of_birth(2i)": "1",
            "provider_verification_claimant_date_of_birth(1i)": "1899"
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_date_of_birth]).to include(
            "Year must be after 1900"
          )
        end
      end
    end

    describe "provider_verification_claimant_national_insurance_number" do
      it do
        is_expected.to(
          validate_presence_of(
            :provider_verification_claimant_national_insurance_number
          ).with_message("Enter the applicant’s National Insurance number")
        )
      end

      it do
        is_expected.to(
          allow_value("QQ123456C")
          .for(:provider_verification_claimant_national_insurance_number)
        )
      end

      it do
        is_expected.to(
          allow_value("QQ 34 56 78 C")
          .for(:provider_verification_claimant_national_insurance_number)
        )
      end

      it do
        is_expected.not_to(
          allow_value("12 34 56 78 C")
          .for(:provider_verification_claimant_national_insurance_number)
        )
      end

      it do
        is_expected.not_to(
          allow_value("QQ 11 56 78 DE")
          .for(:provider_verification_claimant_national_insurance_number)
        )
      end
    end

    describe "provider_verification_claimant_postcode" do
      it do
        is_expected.to(
          validate_presence_of(:provider_verification_claimant_postcode)
            .with_message("Enter the applicant’s postcode")
        )
      end

      it do
        is_expected.not_to(
          allow_value("SW1A").for(:provider_verification_claimant_postcode)
            .with_message("Enter the applicant’s postcode in the correct format")
        )
      end
    end

    describe "provider_verification_claimant_email" do
      context "when missing" do
        it "is invalid" do
          form.provider_verification_claimant_email = ""
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_email]).to include(
            "Enter the applicant’s work email address"
          )
        end
      end

      context "when invalid format" do
        it "is invalid" do
          form.provider_verification_claimant_email = "invalid-email"
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_email]).to include(
            "Enter the applicant’s email address in the correct format, like name@example.com"
          )
        end
      end

      context "when too long" do
        it "is invalid" do
          form.provider_verification_claimant_email = "a" * 120 + "@example.com"
          expect(form).not_to be_valid
          expect(form.errors[:provider_verification_claimant_email]).to include(
            "Email address must be 129 characters or less"
          )
        end
      end

      context "when valid format" do
        it "is valid for this field" do
          form.provider_verification_claimant_email = "test@example.com"
          expect(form.errors[:provider_verification_claimant_email]).to be_empty
        end
      end
    end

    describe "provider_verification_claimant_bank_details_match" do
      it do
        is_expected.not_to(
          allow_value(nil).for(:provider_verification_claimant_bank_details_match)
        )
      end

      it do
        is_expected.to(
          allow_value(true).for(:provider_verification_claimant_bank_details_match)
        )
      end

      it do
        is_expected.to(
          allow_value(false).for(:provider_verification_claimant_bank_details_match)
        )
      end
    end
  end

  describe "#save" do
    context "when form is valid" do
      let(:params) do
        {
          "provider_verification_claimant_date_of_birth(3i)": "21",
          "provider_verification_claimant_date_of_birth(2i)": "1",
          "provider_verification_claimant_date_of_birth(1i)": "1990",
          provider_verification_claimant_national_insurance_number: "QQ123456C",
          provider_verification_claimant_postcode: "NE1 6EE",
          provider_verification_claimant_bank_details_match: true,
          provider_verification_claimant_email: "test@example.com"
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        eligibility = claim.eligibility.reload

        expect(
          eligibility.provider_verification_claimant_date_of_birth
        ).to eq(Date.new(1990, 1, 21))

        expect(
          eligibility.provider_verification_claimant_national_insurance_number
        ).to eq("QQ123456C")

        expect(
          eligibility.provider_verification_claimant_postcode
        ).to eq("NE1 6EE")

        expect(
          eligibility.provider_verification_claimant_bank_details_match
        ).to eq(true)

        expect(
          eligibility.provider_verification_claimant_email
        ).to eq("test@example.com")
      end
    end

    context "when form is invalid" do
      it "returns false" do
        expect(form.save).to be(false)
      end
    end
  end

  describe "#claimant_bank_account_number_obfuscated" do
    let(:claim) do
      create(:claim, :further_education, bank_account_number: "12345678")
    end

    it "returns the obfuscated bank account number" do
      expect(form.claimant_bank_account_number_obfuscated).to eq("****5678")
    end
  end
end
