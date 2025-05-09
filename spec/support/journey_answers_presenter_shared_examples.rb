require "rails_helper"

RSpec.shared_examples "journey answers presenter" do
  describe "#identity_answers" do
    let(:first_name) { "Jo" }
    let(:surname) { "Bloggs" }
    let(:trn) { "1234567" }
    let(:nino) { "QQ123456C" }
    let(:dob) { Date.new(1980, 1, 10) }

    let(:journey_session) do
      build(
        :targeted_retention_incentive_payments_session,
        answers: {
          logged_in_with_tid: logged_in_with_tid,
          teacher_id_user_info: teacher_id_user_info,
          first_name: first_name,
          surname: surname,
          teacher_reference_number: trn,
          date_of_birth: dob,
          national_insurance_number: nino,
          email_address: "test@email.com",
          email_address_check: logged_in_with_tid ? true : false,
          mobile_check: logged_in_with_tid ? "use" : nil,
          provide_mobile_number: true,
          mobile_number: "01234567890",
          address_line_1: "Flat 1",
          address_line_2: "1 Test Road",
          address_line_3: "Test Town",
          postcode: "AB1 2CD",
          payroll_gender: :dont_know
        }
      )
    end

    subject(:answers) do
      described_class.new(journey_session).identity_answers
    end

    context "logged in with Teacher ID" do
      let(:logged_in_with_tid) { true }
      let(:teacher_id_user_info) {
        {
          "given_name" => first_name,
          "family_name" => surname,
          "trn" => trn,
          "birthdate" => dob.to_s,
          "ni_number" => nino,
          "phone_number" => "01234567890",
          "email" => "test@email.com"
        }
      }

      it "returns an array of identity-related questions and answers for displaying to the user for review" do
        expected_answers = [
          [I18n.t("forms.address.questions.your_address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
          [I18n.t("forms.gender.questions.payroll_gender"), "Don’t know", "gender"]
        ]

        expect(answers).to include(*expected_answers)
      end

      context "when the user selected the email provided by Teacher ID" do
        before do
          journey_session.answers.email_address_check = true
        end

        it "includes the selected email and the change slug is `select-email`" do
          expect(answers).to include([I18n.t("forms.select_email.questions.select_email"), "test@email.com", "select-email"])
        end
      end

      context "when the user selected to provide an alternative email" do
        before do
          journey_session.answers.email_address_check = true
        end

        it "includes the user-provided email and the change slug is `select-email`" do
          expect(answers).to include([I18n.t("forms.select_email.questions.select_email"), "test@email.com", "select-email"])
        end
      end

      context "when the email was not provided by Teacher ID" do
        before do
          journey_session.answers.email_address_check = false
        end

        it "includes the user-provided email and the change slug is `email-address`" do
          expect(answers).to include([I18n.t("questions.email_address"), "test@email.com", "email-address"])
        end
      end

      context "when the user selected the mobile provided by Teacher ID" do
        before do
          journey_session.answers.mobile_number = "01234567890"
          journey_session.answers.mobile_check = "use"
          journey_session.answers.provide_mobile_number = true
        end

        it "includes the selected mobile and the change slug is `select-mobile`" do
          expect(answers).to include([I18n.t("forms.select_mobile_form.questions.which_number"), "01234567890", "select-mobile"])
        end

        it "excludes the answer to `provide-mobile-number`" do
          expect(answers.map(&:third)).not_to include("provide-mobile-number")
        end
      end

      context "when the user selected to provide an alternative mobile" do
        before do
          journey_session.answers.mobile_number = "01234567891"
          journey_session.answers.mobile_check = "alternative"
          journey_session.answers.provide_mobile_number = true
        end

        it "includes the user-provided mobile and the change slug is `select-mobile`" do
          expect(answers).to include([I18n.t("forms.select_mobile_form.questions.which_number"), "01234567891", "select-mobile"])
        end

        it "excludes the answer to `provide-mobile-number`" do
          expect(answers.map(&:third)).not_to include("provide-mobile-number")
        end
      end

      context "when the user declined to be contacted by mobile" do
        before do
          journey_session.answers.mobile_number = nil
          journey_session.answers.mobile_check = "declined"
          journey_session.answers.provide_mobile_number = false
        end

        it "includes the answer to decline and the change slug is `select-mobile`" do
          expect(answers).to include([I18n.t("forms.select_mobile_form.questions.which_number"), "I do not want to be contacted by mobile", "select-mobile"])
        end

        it "excludes the answer to `provide-mobile-number`" do
          expect(answers.map(&:third)).not_to include("provide-mobile-number")
        end
      end

      it "excludes answers provided by Teacher ID" do
        expect(answers.map(&:third)).not_to include("personal-details", "teacher-reference-number")
      end
    end

    context "not logged in with Teacher ID" do
      let(:logged_in_with_tid) { false }
      let(:teacher_id_user_info) { {} }

      it "returns an array of identity-related questions and answers for displaying to the user for review" do
        expected_answers = [
          [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
          [I18n.t("forms.address.questions.your_address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
          [I18n.t("questions.date_of_birth"), "10 January 1980", "personal-details"],
          [I18n.t("forms.gender.questions.payroll_gender"), "Don’t know", "gender"],
          [I18n.t("forms.teacher_reference_number.questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
          [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
          [I18n.t("questions.email_address"), "test@email.com", "email-address"],
          [I18n.t("questions.provide_mobile_number"), "Yes", "provide-mobile-number"],
          [I18n.t("questions.mobile_number"), "01234567890", "mobile-number"]
        ]

        expect(answers).to include(*expected_answers)
      end

      context "when the user declined to be contacted by mobile" do
        before do
          journey_session.answers.mobile_number = nil
          journey_session.answers.provide_mobile_number = false
        end

        it "excludes the answer to `mobile-number`" do
          expect(answers.map(&:third)).not_to include("mobile-number")
        end
      end

      it "copes with a blank date of birth" do
        journey_session.answers.date_of_birth = nil
        expect(answers).to include([I18n.t("questions.date_of_birth"), nil, "personal-details"])
      end
    end
  end

  describe "#payment_answers" do
    let(:journey_session) do
      create(
        :targeted_retention_incentive_payments_session,
        answers: {
          bank_sort_code: "123456",
          bank_account_number: "12345678",
          banking_name: "Jo Bloggs"
        }
      )
    end

    subject(:answers) { described_class.new(journey_session).payment_answers }

    context "when a personal bank account is selected" do
      it "returns an array of questions and answers for displaying to the user for review" do
        expected_answers = [
          ["Name on bank account", "Jo Bloggs", "personal-bank-account"],
          ["Bank sort code", "123456", "personal-bank-account"],
          ["Bank account number", "12345678", "personal-bank-account"]
        ]

        expect(answers).to eq expected_answers
      end
    end
  end
end
