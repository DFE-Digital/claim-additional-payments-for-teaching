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

    let(:journey_session) { build(:"#{journey::I18N_NAMESPACE}_session") }

    let(:slug) { "personal-details" }
    let(:params) { {} }

    subject(:form) do
      described_class.new(
        claim: current_claim,
        journey_session: journey_session,
        journey: journey,
        params: ActionController::Parameters.new(slug:, claim: params)
      )
    end

    context "unpermitted claim param" do
      let(:params) { {nonsense_id: 1} }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#show_name_section?" do
      context "when not logged_in_with_tid" do
        it "returns true" do
          expect(form.show_name_section?).to be_truthy
        end
      end

      context "when logged_in_with_tid" do
        let(:logged_in_with_tid) { true }
        let(:teacher_id_user_info) {
          {
            "given_name" => given_name,
            "family_name" => family_name
          }
        }

        context "when the name is different to TID" do
          let(:given_name) { "John" }
          let(:family_name) { "Doe" }

          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, first_name: "Different", surname: "Doe", logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          it "returns true" do
            expect(form.show_name_section?).to be_truthy
          end
        end

        context "when the name is the same as TID" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, first_name: given_name, surname: family_name, logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          context "when the name is not valid" do
            let(:given_name) { "John" }
            let(:family_name) { "D@e" }

            it "returns true" do
              expect(form.show_name_section?).to be_truthy
            end
          end

          context "when the name is blank" do
            let(:given_name) { "" }
            let(:family_name) { "Doe" }

            it "returns true" do
              expect(form.show_name_section?).to be_truthy
            end
          end

          context "when the name is valid" do
            let(:given_name) { "John" }
            let(:family_name) { "Doe" }

            it "returns false" do
              expect(form.show_name_section?).to be_falsey
            end
          end
        end
      end
    end

    describe "#show_date_of_birth_section?" do
      context "when not logged_in_with_tid" do
        it "returns true" do
          expect(form.show_date_of_birth_section?).to be_truthy
        end
      end

      context "when logged_in_with_tid" do
        let(:logged_in_with_tid) { true }
        let(:teacher_id_user_info) {
          {
            "birthdate" => birthdate
          }
        }

        context "when the date_of_birth is different to TID" do
          let(:birthdate) { "1990-01-01" }

          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, date_of_birth: Date.new(1990, 2, 2), logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          it "returns true" do
            expect(form.show_date_of_birth_section?).to be_truthy
          end
        end

        context "when the date_of_birth is the same as TID" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, date_of_birth:, logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          context "when the date_of_birth is blank" do
            let(:birthdate) { "" }
            let(:date_of_birth) { nil }

            it "returns true" do
              expect(form.show_date_of_birth_section?).to be_truthy
            end
          end

          context "when the date_of_birth is valid" do
            let(:birthdate) { "1990-01-01" }
            let(:date_of_birth) { Date.new(1990, 1, 1) }

            it "returns false" do
              expect(form.show_date_of_birth_section?).to be_falsey
            end
          end
        end
      end
    end

    describe "#show_nino_section?" do
      context "when not logged_in_with_tid" do
        it "returns true" do
          expect(form.show_nino_section?).to be_truthy
        end
      end

      context "when logged_in_with_tid" do
        let(:logged_in_with_tid) { true }
        let(:teacher_id_user_info) {
          {
            "ni_number" => ni_number
          }
        }

        context "when the national_insurance_number is different to TID" do
          let(:ni_number) { "AB123456C" }

          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, national_insurance_number: "AB123456D", logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          it "returns true" do
            expect(form.show_nino_section?).to be_truthy
          end
        end

        context "when the national_insurance_number is the same as TID" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:, national_insurance_number:, logged_in_with_tid:, teacher_id_user_info:) }
            CurrentClaim.new(claims: claims)
          end

          context "when the national_insurance_number is blank" do
            let(:ni_number) { "" }
            let(:national_insurance_number) { nil }

            it "returns true" do
              expect(form.show_nino_section?).to be_truthy
            end
          end

          context "when the national_insurance_number is valid" do
            let(:ni_number) { "AB123456C" }
            let(:national_insurance_number) { ni_number }

            it "returns false" do
              expect(form.show_nino_section?).to be_falsey
            end
          end
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
