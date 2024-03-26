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

  describe "#student_loan_answers" do
    let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy:) }
    let(:student_loan_trait) { :with_student_loan }

    subject(:answers) { described_class.new(current_claim).student_loan_answers }
    let(:masters_doctoral_trait) { :with_postgraduate_doctoral_loan_without_postgraduate_masters_loan_when_has_student_loan }

    it "returns an array of question and answers for the student loan and postgraduate masters and doctoral loan questions" do
      expected_answers = [
        [I18n.t("questions.has_student_loan"), "Yes", "student-loan"],
        [I18n.t("questions.student_loan_country"), "England", "student-loan-country"],
        [I18n.t("questions.student_loan_how_many_courses"), "One course", "student-loan-how-many-courses"],
        [
          I18n.t("questions.student_loan_start_date.one_course"),
          I18n.t("answers.student_loan_start_date.one_course.before_first_september_2012"),
          "student-loan-start-date"
        ],
        [I18n.t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
        [I18n.t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
      ]

      expect(answers).to include(*expected_answers)
    end

    context "with the loan start date and answer" do
      let(:student_loan_trait) { :with_student_loan_for_two_courses }

      it "adjusts according to the number of courses answer" do
        expected_answers = [
          [I18n.t("questions.has_student_loan"), "Yes", "student-loan"],
          [I18n.t("questions.student_loan_country"), "England", "student-loan-country"],
          [I18n.t("questions.student_loan_how_many_courses"), "Two or more courses", "student-loan-how-many-courses"],
          [I18n.t("questions.student_loan_start_date.two_or_more_courses"), I18n.t("answers.student_loan_start_date.two_or_more_courses.on_or_after_first_september_2012"), "student-loan-start-date"],
          [I18n.t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
          [I18n.t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
        ]

        expect(answers).to include(*expected_answers)
      end
    end

    context "when it has unanswered questions" do
      let(:student_loan_trait) { :with_unanswered_student_loan_questions }
      let(:masters_doctoral_trait) { :with_no_postgraduate_masters_doctoral_loan }

      it "these are excluded" do
        expect(answers.map(&:third)).not_to include("student-loan-how-many-courses", "student-loan-start-date", "masters-loan", "doctoral-loan")
      end
    end

    context "when claimant answered 'No' to 'Paying off Student Loan' and 'Yes' to 'Take out a Postgraduate Masters or Doctoral Loan'" do
      let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy:, has_masters_doctoral_loan: true) }
      let(:student_loan_trait) { :with_no_student_loan }

      it "returns an array of question and answers for the student loan and postgraduate masters and doctoral loan questions" do
        expected_answers = [
          [I18n.t("questions.has_student_loan"), "No", "student-loan"],
          [I18n.t("questions.has_masters_and_or_doctoral_loan"), "Yes", "masters-doctoral-loan"],
          [I18n.t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
          [I18n.t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
        ]

        expect(answers).to include(*expected_answers)
      end
    end

    context "when claimant answered 'No' to 'Paying off Student Loan' and 'No' to 'Take out a Postgraduate Masters or Doctoral Loan'" do
      let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy:, has_masters_doctoral_loan: false) }
      let(:student_loan_trait) { :with_no_student_loan }

      it "returns an array with a single question and answer for each top level question" do
        expect(answers.map(&:third)).not_to include("masters-loan", "doctoral-loan")
      end
    end
  end
end
