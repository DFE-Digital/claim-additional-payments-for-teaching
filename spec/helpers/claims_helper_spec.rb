require "rails_helper"

describe ClaimsHelper do
  describe "#eligibility_answers" do
    let(:school) { create(:school) }
    let(:eligibility) do
      build(
        :student_loans_eligibility,
        :eligible,
        qts_award_year: "on_or_after_cut_off_date"
      )
    end
    let(:claim) do
      build(:claim, eligibility: eligibility)
    end

    let(:current_claim) { CurrentClaim.new(claims: [claim]) }

    it "returns the correct answers for the eligibility's policy" do
      answers = helper.eligibility_answers(current_claim)
      expect(answers.first).to eq [I18n.t("student_loans.questions.qts_award_year"), "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year", "qts-year"]
    end
  end

  describe "#identity_answers" do
    let(:first_name) { "Jo" }
    let(:surname) { "Bloggs" }
    let(:trn) { "1234567" }
    let(:nino) { "QQ123456C" }
    let(:dob) { Date.new(1980, 1, 10) }

    let(:claim) do
      build(
        :claim,
        policy: policy,
        first_name: first_name,
        surname: surname,
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: dob,
        teacher_reference_number: trn,
        national_insurance_number: nino,
        email_address: "test@email.com",
        payroll_gender: :dont_know,
        logged_in_with_tid: logged_in_with_tid,
        teacher_id_user_info: teacher_id_user_info
      )
    end

    context "for a claim with a policy of StudentLoans" do
      let(:policy) { Policies::StudentLoans }

      context "logged in with tid" do
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

        it "excludes answers provided by tid" do
          expected_answers = [
            [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
            [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
            [I18n.t("questions.email_address"), "test@email.com", "email-address"]
          ]

          expect(helper.identity_answers(claim)).to eq expected_answers
        end
      end

      context "not logged in with tid" do
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

          expect(helper.identity_answers(claim)).to eq expected_answers
        end

        it "copes with a blank date of birth" do
          claim.date_of_birth = nil

          expected_answers = [
            [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
            [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
            [I18n.t("questions.date_of_birth"), nil, "personal-details"],
            [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
            [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
            [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
            [I18n.t("questions.email_address"), "test@email.com", "email-address"]
          ]

          expect(helper.identity_answers(claim)).to eq expected_answers
        end
      end
    end

    context "for a claim with a policy of EarlyCareerPayments" do
      let(:policy) { Policies::EarlyCareerPayments }

      context "logged in with tid" do
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

        it "excludes answers provided by tid" do
          expected_answers = [
            [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
            [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
            [I18n.t("questions.email_address"), "test@email.com", "email-address"],
            [I18n.t("questions.provide_mobile_number"), "No", "provide-mobile-number"]
          ]

          expect(helper.identity_answers(claim)).to eq expected_answers
        end
      end

      context "not logged in with tid" do
        let(:logged_in_with_tid) { false }
        let(:teacher_id_user_info) { {} }

        it "returns an array of identity-related questions and answers for displaying to the user for review" do
          claim.provide_mobile_number = "Yes"
          claim.mobile_number = "01234567899"

          expected_answers = [
            [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
            [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
            [I18n.t("questions.date_of_birth"), "10 January 1980", "personal-details"],
            [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
            [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
            [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
            [I18n.t("questions.email_address"), "test@email.com", "email-address"],
            [I18n.t("questions.provide_mobile_number"), "Yes", "provide-mobile-number"],
            [I18n.t("questions.mobile_number"), "01234567899", "mobile-number"]
          ]

          expect(helper.identity_answers(claim)).to eq expected_answers
        end

        it "copes with a blank date of birth" do
          claim.date_of_birth = nil

          expected_answers = [
            [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
            [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
            [I18n.t("questions.date_of_birth"), nil, "personal-details"],
            [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
            [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
            [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
            [I18n.t("questions.email_address"), "test@email.com", "email-address"],
            [I18n.t("questions.provide_mobile_number"), "No", "provide-mobile-number"]
          ]

          expect(helper.identity_answers(claim)).to eq expected_answers
        end
      end
    end
  end

  describe "#payment_answers" do
    context "when a personal bank account is selected" do
      it "returns an array of questions and answers for displaying to the user for review" do
        claim = create(:claim,
          bank_or_building_society: :personal_bank_account,
          bank_sort_code: "12 34 56",
          bank_account_number: "12 34 56 78",
          banking_name: "Jo Bloggs")

        expected_answers = [
          [t("questions.bank_or_building_society"), "Personal bank account", "bank-or-building-society"],
          ["Name on bank account", "Jo Bloggs", "personal-bank-account"],
          ["Bank sort code", "123456", "personal-bank-account"],
          ["Bank account number", "12345678", "personal-bank-account"]
        ]

        expect(helper.payment_answers(claim)).to eq expected_answers
      end
    end

    context "when a building society is selected" do
      it "returns an array of questions and answers for displaying to the user for review" do
        claim = create(:claim,
          bank_or_building_society: :building_society,
          bank_sort_code: "65 90 07",
          bank_account_number: "90 77 02 24",
          banking_name: "David Badger-Hillary",
          building_society_roll_number: "5890/87654321")

        expected_answers = [
          [t("questions.bank_or_building_society"), "Building society", "bank-or-building-society"],
          ["Name on bank account", "David Badger-Hillary", "building-society-account"],
          ["Bank sort code", "659007", "building-society-account"],
          ["Bank account number", "90770224", "building-society-account"],
          ["Building society roll number", "5890/87654321", "building-society-account"]
        ]

        expect(helper.payment_answers(claim)).to eq expected_answers
      end
    end
  end
end
