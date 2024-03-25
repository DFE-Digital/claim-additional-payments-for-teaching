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
    let(:teacher_reference_number) { "1234567" }
    let(:national_insurance_number) { "QQ123456C" }
    let(:date_of_birth) { Date.new(1980, 1, 10) }

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
        date_of_birth:,
        teacher_reference_number:,
        national_insurance_number:,
        email_address_check:,
        email_address: "test@email.com",
        mobile_check:,
        provide_mobile_number: true,
        mobile_number: "01234567890",
        payroll_gender: :dont_know,
        logged_in_with_tid:,
        teacher_id_user_info:
      )
    end

    let(:teacher_id_user_info) {
      {
        "given_name" => first_name,
        "family_name" => surname,
        "trn" => teacher_reference_number,
        "birthdate" => date_of_birth.to_s,
        "ni_number" => national_insurance_number,
        "phone_number" => "01234567890",
        "email" => "test@email.com"
      }
    }

    [Policies::StudentLoans, Policies::EarlyCareerPayments].each do |policy|
      context "for a claim with a policy of #{policy}" do
        let(:policy) { policy }

        context "logged in with Teacher ID" do
          let(:logged_in_with_tid) { true }

          context "when the user could make a selection for email and phone number" do
            let(:email_address_check) { true }
            let(:mobile_check) { "use" }

            it "includes only answers provided by the user, including the email and mobile number from Teacher ID" do
              expected_answers = [
                [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
                [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
                [I18n.t("questions.select_email.heading"), "test@email.com", "select-email"],
                [I18n.t("questions.select_phone_number.heading"), "01234567890", "select-mobile"]
              ]

              expect(helper.identity_answers(claim)).to eq expected_answers
            end

            it "does not display the mobile number when the user declined to be contacted by mobile" do
              claim.provide_mobile_number = false
              claim.mobile_number = nil
              claim.mobile_check = "decline"

              expected_answers = [
                [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
                [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
                [I18n.t("questions.select_email.heading"), "test@email.com", "select-email"],
                [I18n.t("questions.select_phone_number.heading"), "I do not want to be contacted by mobile", "select-mobile"]
              ]

              expect(helper.identity_answers(claim)).to eq expected_answers
            end
          end

          context "when the user could not make a selection for email and phone number" do
            let(:email_address_check) { nil }
            let(:mobile_check) { nil }

            it "includes only answers provided by the user, including the email and mobile number provided manually" do
              expected_answers = [
                [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
                [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
                [I18n.t("questions.email_address"), "test@email.com", "email-address"],
                [I18n.t("questions.provide_mobile_number"), "Yes", "provide-mobile-number"],
                [I18n.t("questions.mobile_number"), "01234567890", "mobile-number"]
              ]

              expect(helper.identity_answers(claim)).to eq expected_answers
            end

            it "does not display the mobile number when the user declined to be contacted by mobile" do
              claim.provide_mobile_number = false
              claim.mobile_number = nil

              expected_answers = [
                [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
                [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
                [I18n.t("questions.email_address"), "test@email.com", "email-address"],
                [I18n.t("questions.provide_mobile_number"), "No", "provide-mobile-number"]
              ]

              expect(helper.identity_answers(claim)).to eq expected_answers
            end
          end
        end

        context "not logged in with Teacher ID" do
          let(:logged_in_with_tid) { false }
          let(:teacher_id_user_info) { {} }
          let(:email_address_check) { nil }
          let(:mobile_check) { nil }

          it "returns an array of identity-related questions and answers for displaying to the user for review" do
            expected_answers = [
              [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
              [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
              [I18n.t("questions.date_of_birth"), "10 January 1980", "personal-details"],
              [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
              [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
              [I18n.t("questions.national_insurance_number"), "QQ123456C", "personal-details"],
              [I18n.t("questions.email_address"), "test@email.com", "email-address"],
              [I18n.t("questions.provide_mobile_number"), "Yes", "provide-mobile-number"],
              [I18n.t("questions.mobile_number"), "01234567890", "mobile-number"]
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
              [I18n.t("questions.provide_mobile_number"), "Yes", "provide-mobile-number"],
              [I18n.t("questions.mobile_number"), "01234567890", "mobile-number"]
            ]

            expect(helper.identity_answers(claim)).to eq expected_answers
          end

          it "does not display the mobile number when one has not been provided" do
            claim.provide_mobile_number = false
            claim.mobile_number = nil

            expected_answers = [
              [I18n.t("questions.name"), "Jo Bloggs", "personal-details"],
              [I18n.t("questions.address.generic.title"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
              [I18n.t("questions.date_of_birth"), "10 January 1980", "personal-details"],
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

  describe "#student_loan_answers" do
    let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy: policy, eligibility: eligibility) }
    let(:student_loan_trait) { :with_student_loan }

    context "TSLR (Student Loans) policy" do
      let(:policy) { Policies::StudentLoans }
      let(:eligibility) { build(:student_loans_eligibility, student_loan_repayment_amount: 1987.65) }
      let(:masters_doctoral_trait) { :with_postgraduate_masters_loan_without_postgraduate_doctoral_loan_when_has_student_loan }

      before { create(:journey_configuration, :student_loans) }

      it "returns an array of question and answers for the student loan and postgraduate masters and doctoral loan questions" do
        expected_answers = [
          [t("questions.has_student_loan"), "Yes", "student-loan"],
          [t("questions.student_loan_country"), "England", "student-loan-country"],
          [t("questions.student_loan_how_many_courses"), "One course", "student-loan-how-many-courses"],
          [
            t("questions.student_loan_start_date.one_course"),
            t("answers.student_loan_start_date.one_course.before_first_september_2012"),
            "student-loan-start-date"
          ],
          [t("questions.postgraduate_masters_loan"), "Yes", "masters-loan"],
          [t("questions.postgraduate_doctoral_loan"), "No", "doctoral-loan"],
          [t("student_loans.questions.student_loan_amount", financial_year: Policies::StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
        ]

        expect(helper.student_loan_answers(claim)).to eq expected_answers
      end

      context "with the loan start date and answer" do
        let(:student_loan_trait) { :with_student_loan_for_two_courses }

        it "adjusts according to the number of courses answer" do
          expected_answers = [
            [t("questions.has_student_loan"), "Yes", "student-loan"],
            [t("questions.student_loan_country"), "England", "student-loan-country"],
            [t("questions.student_loan_how_many_courses"), "Two or more courses", "student-loan-how-many-courses"],
            [
              t("questions.student_loan_start_date.two_or_more_courses"),
              t("answers.student_loan_start_date.two_or_more_courses.on_or_after_first_september_2012"),
              "student-loan-start-date"
            ],
            [t("questions.postgraduate_masters_loan"), "Yes", "masters-loan"],
            [t("questions.postgraduate_doctoral_loan"), "No", "doctoral-loan"],
            [t("student_loans.questions.student_loan_amount", financial_year: Policies::StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end

      context "when it has unanswered questions" do
        let(:student_loan_trait) { :with_unanswered_student_loan_questions }
        let(:masters_doctoral_trait) { :with_no_postgraduate_masters_doctoral_loan }

        it "these are excluded" do
          expected_answers = [
            [t("questions.has_student_loan"), "Yes", "student-loan"],
            [t("questions.student_loan_country"), "Scotland", "student-loan-country"],
            [t("student_loans.questions.student_loan_amount", financial_year: Policies::StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end
    end

    context "Early-Career Payment policy" do
      let(:policy) { Policies::EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility) }
      let(:masters_doctoral_trait) { :with_postgraduate_doctoral_loan_without_postgraduate_masters_loan_when_has_student_loan }

      it "returns an array of question and answers for the student loan and postgraduate masters and doctoral loan questions" do
        expected_answers = [
          [t("questions.has_student_loan"), "Yes", "student-loan"],
          [t("questions.student_loan_country"), "England", "student-loan-country"],
          [t("questions.student_loan_how_many_courses"), "One course", "student-loan-how-many-courses"],
          [
            t("questions.student_loan_start_date.one_course"),
            t("answers.student_loan_start_date.one_course.before_first_september_2012"),
            "student-loan-start-date"
          ],
          [t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
          [t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
        ]

        expect(helper.student_loan_answers(claim)).to eq expected_answers
      end

      context "with the loan start date and answer" do
        let(:student_loan_trait) { :with_student_loan_for_two_courses }

        it "adjusts according to the number of courses answer" do
          expected_answers = [
            [t("questions.has_student_loan"), "Yes", "student-loan"],
            [t("questions.student_loan_country"), "England", "student-loan-country"],
            [t("questions.student_loan_how_many_courses"), "Two or more courses", "student-loan-how-many-courses"],
            [t("questions.student_loan_start_date.two_or_more_courses"), t("answers.student_loan_start_date.two_or_more_courses.on_or_after_first_september_2012"), "student-loan-start-date"],
            [t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
            [t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end

      context "when it has unanswered questions" do
        let(:student_loan_trait) { :with_unanswered_student_loan_questions }
        let(:masters_doctoral_trait) { :with_no_postgraduate_masters_doctoral_loan }

        it "these are excluded" do
          expected_answers = [
            [t("questions.has_student_loan"), "Yes", "student-loan"],
            [t("questions.student_loan_country"), "Scotland", "student-loan-country"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end

      context "when claimant answered 'No' to 'Paying off Student Loan' and 'Yes' to 'Take out a Postgraduate Masters or Doctoral Loan'" do
        let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy: Policies::EarlyCareerPayments, has_masters_doctoral_loan: true, eligibility: eligibility) }
        let(:eligibility) { build(:early_career_payments_eligibility) }
        let(:student_loan_trait) { :with_no_student_loan }

        it "returns an array of question and answers for the student loan and postgraduate masters and doctoral loan questions" do
          expected_answers = [
            [t("questions.has_student_loan"), "No", "student-loan"],
            [t("questions.has_masters_and_or_doctoral_loan"), "Yes", "masters-doctoral-loan"],
            [t("questions.postgraduate_masters_loan"), "No", "masters-loan"],
            [t("questions.postgraduate_doctoral_loan"), "Yes", "doctoral-loan"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end

      context "when claimant answered 'No' to 'Paying off Student Loan' and 'No' to 'Take out a Postgraduate Masters or Doctoral Loan'" do
        let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, policy: Policies::EarlyCareerPayments, has_masters_doctoral_loan: false, eligibility: eligibility) }
        let(:eligibility) { build(:early_career_payments_eligibility) }
        let(:student_loan_trait) { :with_no_student_loan }

        it "returns an array with a single question and answer for each top level question" do
          expected_answers = [
            [t("questions.has_student_loan"), "No", "student-loan"],
            [t("questions.has_masters_and_or_doctoral_loan"), "No", "masters-doctoral-loan"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end
    end
  end
end
