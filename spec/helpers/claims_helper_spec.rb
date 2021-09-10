require "rails_helper"

describe ClaimsHelper do
  describe "#eligibility_answers" do
    let(:school) { schools(:penistone_grammar_school) }
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

    it "returns the correct answers for the eligibility's policy" do
      answers = helper.eligibility_answers(claim)
      expect(answers.first).to eq [I18n.t("questions.qts_award_year"), "In or after the academic year 2013 to 2014", "qts-year"]
    end
  end

  describe "#identity_answers" do
    let(:claim) do
      build(
        :claim,
        policy: policy,
        first_name: "Jo",
        surname: "Bloggs",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: Date.new(1980, 1, 10),
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ123456C",
        email_address: "test@email.com",
        payroll_gender: :dont_know
      )
    end

    context "for a claim with a policy of StudentLoans" do
      let(:policy) { StudentLoans }

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

      it "excludes questions/answers that were acquired from GOV.UK Verify" do
        claim.govuk_verify_fields = ["first_name", "surname", "date_of_birth", "payroll_gender", "postcode"]

        expected_answers = [
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

    context "for a claim with a policy of EarlyCareerPayments" do
      let(:policy) { EarlyCareerPayments }

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
    let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, eligibility: eligibility) }
    let(:student_loan_trait) { :with_student_loan }

    context "TSLR (Student Loans) policy" do
      let(:eligibility) { build(:student_loans_eligibility, student_loan_repayment_amount: 1987.65) }
      let(:masters_doctoral_trait) { :with_postgraduate_masters_loan_without_postgraduate_doctoral_loan_when_has_student_loan }

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
          [t("student_loans.questions.student_loan_amount", financial_year: StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
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
            [t("student_loans.questions.student_loan_amount", financial_year: StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
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
            [t("student_loans.questions.student_loan_amount", financial_year: StudentLoans.current_financial_year), "£1,987.65", "student-loan-amount"]
          ]

          expect(helper.student_loan_answers(claim)).to eq expected_answers
        end
      end
    end

    context "Early-Career Payment policy" do
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
        let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, has_masters_doctoral_loan: true, eligibility: eligibility) }
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
        let(:claim) { build(:claim, student_loan_trait, masters_doctoral_trait, has_masters_doctoral_loan: false, eligibility: eligibility) }
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
