require "rails_helper"

describe ClaimsHelper do
  describe "#options_for_qts_award_year" do
    it "returns an array of the valid years as label/value pairs for use as select options" do
      expected_options = [
        ["September 1 2013 - August 31 2014", "2013-2014"],
        ["September 1 2014 - August 31 2015", "2014-2015"],
        ["September 1 2015 - August 31 2016", "2015-2016"],
        ["September 1 2016 - August 31 2017", "2016-2017"],
        ["September 1 2017 - August 31 2018", "2017-2018"],
        ["September 1 2018 - August 31 2019", "2018-2019"],
        ["September 1 2019 - August 31 2020", "2019-2020"],
      ]

      expect(helper.options_for_qts_award_year).to eq expected_options
    end
  end

  describe "#claim_answers" do
    it "returns an array of questions and answers for displaying to the user for review" do
      school = create(:school)
      claim = TslrClaim.create(
        qts_award_year: "2013-2014",
        claim_school: school,
        current_school: school,
        mostly_teaching_eligible_subjects: true,
        student_loan_repayment_amount: 1987.65,
      )

      expected_answers = [
        [I18n.t("tslr.questions.qts_award_year"), "September 1 2013 - August 31 2014", "qts-year"],
        [I18n.t("tslr.questions.claim_school"), school.name, "claim-school"],
        [I18n.t("tslr.questions.current_school"), school.name, "current-school"],
        [I18n.t("tslr.questions.mostly_teaching_eligible_subjects"), "Yes", "subjects-taught"],
        [I18n.t("tslr.questions.student_loan_amount", claim_school_name: school.name), "£1,987.65", "student-loan-amount"],
      ]

      expect(helper.claim_answers(claim)).to eq expected_answers
    end
  end

  describe "#identity_answers" do
    it "returns an array of questions and answers for displaying to the user for review" do
      claim = TslrClaim.create(
        full_name: "Jo Bloggs",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: 20.years.ago.to_date,
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ 12 34 56 C",
        email_address: "test@email.com",
        bank_account_number: "12 34 56 78",
        bank_sort_code: "12 34 56",
      )

      expected_answers = [
        ["Full name", "Jo Bloggs", "full-name"],
        ["Address", "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
        ["Date of birth", I18n.l(20.years.ago.to_date), "date-of-birth"],
        ["Teacher reference number", "1234567", "teacher-reference-number"],
        ["National Insurance number", "QQ123456C", "national-insurance-number"],
        ["Email address", "test@email.com", "email-address"],
        ["Account number", "12345678", "bank-details"],
        ["Sort code", "123456", "bank-details"],
      ]

      expect(helper.identity_answers(claim)).to eq expected_answers
    end
  end

  describe "subject_list" do
    let(:list) { subject_list(subjects) }

    context "with two subjects" do
      let(:subjects) { [:biology_taught, :chemistry_taught] }

      it "seperates the subjects with 'and" do
        expect(list).to eq("Biology and Chemistry")
      end
    end

    context "with three subjects" do
      let(:subjects) { [:biology_taught, :chemistry_taught, :physics_taught] }

      it "returns a comma separated list with a final 'and'" do
        expect(list).to eq("Biology, Chemistry and Physics")
      end
    end
  end
end
