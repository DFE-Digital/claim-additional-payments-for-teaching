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

    it "returns an array of identity-related questions and answers for displaying to the user for review" do
      expected_answers = [
        [I18n.t("questions.name"), "Jo Bloggs", "name"],
        [I18n.t("questions.address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
        [I18n.t("questions.date_of_birth"), "10 January 1980", "date-of-birth"],
        [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
        [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
        [I18n.t("questions.national_insurance_number"), "QQ123456C", "national-insurance-number"],
        [I18n.t("questions.email_address"), "test@email.com", "email-address"]
      ]

      expect(helper.identity_answers(claim)).to eq expected_answers
    end

    it "excludes questions/answers that were acquired from GOV.UK Verify" do
      claim.govuk_verify_fields = ["first_name", "surname", "date_of_birth", "payroll_gender", "postcode"]

      expected_answers = [
        [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
        [I18n.t("questions.national_insurance_number"), "QQ123456C", "national-insurance-number"],
        [I18n.t("questions.email_address"), "test@email.com", "email-address"]
      ]

      expect(helper.identity_answers(claim)).to eq expected_answers
    end

    it "copes with a blank date of birth" do
      claim.date_of_birth = nil

      expected_answers = [
        [I18n.t("questions.name"), "Jo Bloggs", "name"],
        [I18n.t("questions.address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
        [I18n.t("questions.date_of_birth"), nil, "date-of-birth"],
        [I18n.t("questions.payroll_gender"), "Don’t know", "gender"],
        [I18n.t("questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
        [I18n.t("questions.national_insurance_number"), "QQ123456C", "national-insurance-number"],
        [I18n.t("questions.email_address"), "test@email.com", "email-address"]
      ]

      expect(helper.identity_answers(claim)).to eq expected_answers
    end
  end

  describe "#payment_answers" do
    it "returns an array of questions and answers for displaying to the user for review" do
      claim = create(:claim,
        bank_sort_code: "12 34 56",
        bank_account_number: "12 34 56 78",
        banking_name: "Jo Bloggs")

      expected_answers = [
        ["Name on bank account", "Jo Bloggs", "bank-details"],
        ["Bank sort code", "123456", "bank-details"],
        ["Bank account number", "12345678", "bank-details"]
      ]

      expect(helper.payment_answers(claim)).to eq expected_answers
    end

    it "returns a roll number if one is provided" do
      claim = create(:claim, building_society_roll_number: "1234/12345678")

      expect(helper.payment_answers(claim)).to include(
        ["Building society roll number", "1234/12345678", "bank-details"]
      )
    end
  end

  describe "#student_loan_answers" do
    it "returns an array of question and answers for the student loan questions" do
      claim = build(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoan::ENGLAND,
        student_loan_courses: :one_course,
        student_loan_start_date: StudentLoan::ON_OR_AFTER_1_SEPT_2012,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1987.65)
      )

      expected_answers = [
        [t("questions.has_student_loan"), "Yes", "student-loan"],
        [t("questions.student_loan_country"), "England", "student-loan-country"],
        [t("questions.student_loan_how_many_courses"), "One course", "student-loan-how-many-courses"],
        [t("questions.student_loan_start_date.one_course"), t("answers.student_loan_start_date.one_course.on_or_after_first_september_2012"), "student-loan-start-date"]
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end

    it "adjusts the loan start date question and answer according to the number of courses answer" do
      claim = build(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoan::ENGLAND,
        student_loan_courses: :two_or_more_courses,
        student_loan_start_date: StudentLoan::BEFORE_1_SEPT_2012,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1987.65)
      )

      expected_answers = [
        [t("questions.has_student_loan"), "Yes", "student-loan"],
        [t("questions.student_loan_country"), "England", "student-loan-country"],
        [t("questions.student_loan_how_many_courses"), "Two or more courses", "student-loan-how-many-courses"],
        [t("questions.student_loan_start_date.two_or_more_courses"), t("answers.student_loan_start_date.two_or_more_courses.before_first_september_2012"), "student-loan-start-date"]
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end

    it "excludes unanswered questions" do
      claim = build(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoan::SCOTLAND,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1987.65)
      )

      expected_answers = [
        [t("questions.has_student_loan"), "Yes", "student-loan"],
        [t("questions.student_loan_country"), "Scotland", "student-loan-country"]
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end
  end
end
