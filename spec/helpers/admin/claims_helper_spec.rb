require "rails_helper"

describe Admin::ClaimsHelper do
  let(:claim_school) { schools(:penistone_grammar_school) }
  let(:current_school) { create(:school, :tslr_eligible) }

  describe "eligibility_answers" do
    let(:eligibility) do
      build(
        :student_loans_eligibility,
        qts_award_year: "2013_2014",
        claim_school: claim_school,
        current_school: current_school,
        chemistry_taught: true,
        physics_taught: true,
        had_leadership_position: true,
        mostly_performed_leadership_duties: false,
        student_loan_repayment_amount: 1987.65,
      )
    end

    it "returns an array of questions and answers for displaying to approver" do
      expected_answers = [
        [I18n.t("student_loans.questions.admin.qts_award_year"), "1 September 2013 to 31 August 2014"],
        [I18n.t("student_loans.questions.admin.claim_school"), claim_school.name],
        [I18n.t("questions.admin.current_school"), current_school.name],
        [I18n.t("student_loans.questions.admin.subjects_taught"), "Chemistry and Physics"],
        [I18n.t("student_loans.questions.admin.had_leadership_position"), "Yes"],
        [I18n.t("student_loans.questions.admin.mostly_performed_leadership_duties"), "No"],
      ]

      expect(helper.admin_eligibility_answers(eligibility)).to eq expected_answers
    end

    it "excludes questions skipped from the flow" do
      eligibility.had_leadership_position = false
      expect(helper.admin_eligibility_answers(eligibility)).to include([I18n.t("student_loans.questions.admin.had_leadership_position"), "No"])
      expect(helper.admin_eligibility_answers(eligibility)).to_not include([I18n.t("student_loans.questions.admin.mostly_performed_leadership_duties"), "No"])
    end
  end

  describe "identity_answers" do
    let(:claim) do
      build(
        :claim,
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ123456C",
        email_address: "test@email.com"
      )
    end

    it "includes an array of questions and answers" do
      expected_answers = [
        [I18n.t("questions.admin.teacher_reference_number"), "1234567"],
        [I18n.t("questions.admin.national_insurance_number"), "QQ123456C"],
        [I18n.t("questions.admin.email_address"), "test@email.com"],
      ]

      expect(helper.admin_identity_answers(claim)).to eq expected_answers
    end
  end
end
