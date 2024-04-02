require "rails_helper"

RSpec.shared_examples "journey answers presenter" do
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  describe "#identity_answers" do
    let(:first_name) { "Jo" }
    let(:surname) { "Bloggs" }
    let(:trn) { "1234567" }
    let(:nino) { "QQ123456C" }
    let(:dob) { Date.new(1980, 1, 10) }

    let(:claim) do
      build(
        :claim,
        policy:,
        first_name:,
        surname:,
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: dob,
        teacher_reference_number: trn,
        national_insurance_number: nino,
        email_address: "test@email.com",
        payroll_gender: :dont_know,
        logged_in_with_tid:,
        teacher_id_user_info:
      )
    end

    subject(:answers) { described_class.new(current_claim).identity_answers }

    context "logged in with Teacher ID" do
      let(:logged_in_with_tid) { true }
      let(:teacher_id_user_info) {
        {
          "given_name" => first_name,
          "family_name" => surname,
          "trn" => trn,
          "birthdate" => dob.to_s,
          "ni_number" => nino
        }
      }

      it "returns an array of identity-related questions and answers for displaying to the user for review" do
        expected_answers = [
          [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
          [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
          [I18n.t("questions.email_address"), "test@email.com", "email-address"]
        ]

        expect(answers).to include(*expected_answers)
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
          [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
          [I18n.t("questions.date_of_birth"), "10 January 1980", "personal-details"],
          [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
          [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
          [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
          [I18n.t("questions.email_address"), "test@email.com", "email-address"]
        ]

        expect(answers).to include(*expected_answers)
      end

      it "copes with a blank date of birth" do
        claim.date_of_birth = nil
        expect(answers).to include([I18n.t("questions.date_of_birth"), nil, "personal-details"])
      end
    end
  end

  describe "#payment_answers" do
    let(:claim) { create(:claim, bank_or_building_society: :personal_bank_account, bank_sort_code: "12 34 56", bank_account_number: "12 34 56 78", banking_name: "Jo Bloggs") }

    subject(:answers) { described_class.new(current_claim).payment_answers }

    context "when a personal bank account is selected" do
      it "returns an array of questions and answers for displaying to the user for review" do
        expected_answers = [
          [I18n.t("questions.bank_or_building_society"), "Personal bank account", "bank-or-building-society"],
          ["Name on bank account", "Jo Bloggs", "personal-bank-account"],
          ["Bank sort code", "123456", "personal-bank-account"],
          ["Bank account number", "12345678", "personal-bank-account"]
        ]

        expect(answers).to eq expected_answers
      end
    end

    context "when a building society is selected" do
      let(:claim) { create(:claim, bank_or_building_society: :building_society, bank_sort_code: "65 90 07", bank_account_number: "90 77 02 24", banking_name: "David Badger-Hillary", building_society_roll_number: "5890/87654321") }

      it "returns an array of questions and answers for displaying to the user for review" do
        expected_answers = [
          [I18n.t("questions.bank_or_building_society"), "Building society", "bank-or-building-society"],
          ["Name on bank account", "David Badger-Hillary", "building-society-account"],
          ["Bank sort code", "659007", "building-society-account"],
          ["Bank account number", "90770224", "building-society-account"],
          ["Building society roll number", "5890/87654321", "building-society-account"]
        ]

        expect(answers).to eq expected_answers
      end
    end
  end
end
