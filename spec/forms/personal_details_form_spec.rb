require "rails_helper"

RSpec.describe PersonalDetailsForm, type: :model do
  shared_examples "personal_details_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "personal-details" }
    let(:params) { {} }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: ActionController::Parameters.new(slug:, claim: params)) }

    context "unpermitted claim param" do
      let(:params) { {nonsense_id: 1} }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#has_valid_name?" do
      context "valid" do
        let(:params) { {first_name: "John", surname: "Doe"} }

        it "returns true" do
          expect(form.has_valid_name?).to be true
        end
      end

      context "invalid first_name" do
        let(:params) { {first_name: "J@hn", surname: "Doe"} }

        it "returns false" do
          expect(form.has_valid_name?).to be false
        end
      end

      context "invalid surname" do
        let(:params) { {first_name: "J@hn", surname: "D@e"} }

        it "returns false" do
          expect(form.has_valid_name?).to be false
        end
      end

      context "blank" do
        let(:params) { {first_name: "", surname: ""} }

        it "returns false" do
          expect(form.has_valid_name?).to be false
        end
      end
    end

    describe "#has_valid_date_of_birth?" do
      context "valid" do
        let(:params) { {day: 11, month: 1, year: 1980} }

        it "returns true" do
          expect(form.has_valid_date_of_birth?).to be true
        end
      end

      context "nil" do
        let(:params) { {day: nil, month: nil, year: nil} }

        it "returns false" do
          expect(form.has_valid_date_of_birth?).to be false
        end
      end
    end

    describe "#has_valid_nino?" do
      context "valid" do
        let(:params) { {national_insurance_number: "JH001234D"} }

        it "returns true" do
          expect(form.has_valid_nino?).to be true
        end
      end

      context "nil" do
        let(:nino) { nil }

        it "returns false" do
          expect(form.has_valid_nino?).to be false
        end
      end
    end

    describe "validations" do
      it { should validate_presence_of(:first_name).with_message("Enter your first name") }
      it { should validate_length_of(:first_name).is_at_most(100).with_message("First name must be less than 100 characters") }
      it { should_not allow_value("*").for(:first_name).with_message("First name cannot contain special characters") }
      it { should allow_value("O'Brian").for(:first_name) }

      it { should validate_length_of(:middle_name).is_at_most(61).with_message("Middle names must be less than 61 characters") }
      it { should_not allow_value("&").for(:middle_name).with_message("Middle names cannot contain special characters") }
      it { should allow_value("O'Brian").for(:middle_name) }

      it { should validate_presence_of(:surname).with_message("Enter your last name") }
      it { should validate_length_of(:surname).is_at_most(100).with_message("Last name must be less than 100 characters") }
      it { should_not allow_value("$").for(:surname).with_message("Last name cannot contain special characters") }
      it { should allow_value("O'Brian").for(:surname) }

      it { should validate_presence_of(:national_insurance_number).with_message("Enter a National Insurance number in the correct format") }
      it { should allow_value("QQ123456C").for(:national_insurance_number) }
      it { should allow_value("QQ 34 56 78 C").for(:national_insurance_number) }
      it { should_not allow_value("12 34 56 78 C").for(:national_insurance_number) }
      it { should_not allow_value("QQ 11 56 78 DE").for(:national_insurance_number) }

      describe "#date_of_birth" do
        before do
          form.validate
        end

        context "when in the future" do
          let(:params) { {day: 1, month: 1, year: Time.zone.today.year + 1} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Date of birth must be in the past")
          end
        end

        context "when it's incomplete" do
          let(:params) { {day: nil, month: 1, year: 1990} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Date of birth must include a day, month and year in the correct format, for example 01 01 1980")
          end
        end

        context "when it's complete but invalid" do
          let(:params) { {day: 1, month: 13, year: 1990} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Enter a date of birth in the correct format")
          end
        end

        context "when it's missing" do
          let(:params) { {day: nil, month: nil, year: nil} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Enter your date of birth")
          end
        end
        context "when the year doesn't have 4 digits" do
          let(:params) { {day: 1, month: 1, year: 90} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Year must include 4 numbers")
          end
        end

        context "when the year is before 1900" do
          let(:params) { {day: 1, month: 1, year: 1899} }

          it "returns an error" do
            expect(form.errors[:date_of_birth]).to include("Year must be after 1900")
          end
        end
      end
    end

    describe "#save" do
      context "with valid params" do
        let(:params) do
          {
            first_name: "Dr",
            middle_name: "Bob",
            surname: "Loblaw",
            day: 1,
            month: 1,
            year: 1990,
            national_insurance_number: "QQ123456C"
          }
        end

        it "updates the claim" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            expect(claim.first_name).to eq "Dr"
            expect(claim.middle_name).to eq "Bob"
            expect(claim.surname).to eq "Loblaw"
            expect(claim.date_of_birth).to eq Date.new(1990, 1, 1)
            expect(claim.national_insurance_number).to eq "QQ123456C"
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "personal_details_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "personal_details_form", Journeys::AdditionalPaymentsForTeaching
  end
end
