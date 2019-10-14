require "rails_helper"

describe Admin::ClaimsHelper do
  let(:claim_school) { schools(:penistone_grammar_school) }
  let(:current_school) { create(:school, :student_loan_eligible) }

  describe "#eligibility_answers" do
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
        [I18n.t("student_loans.admin.qts_award_year"), "1 September 2013 to 31 August 2014"],
        [I18n.t("student_loans.admin.claim_school"), helper.display_school(claim_school)],
        [I18n.t("admin.current_school"), helper.display_school(current_school)],
        [I18n.t("student_loans.admin.subjects_taught"), "Chemistry and Physics"],
        [I18n.t("student_loans.admin.had_leadership_position"), "Yes"],
        [I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"],
      ]

      expect(helper.admin_eligibility_answers(eligibility)).to eq expected_answers
    end

    it "excludes questions skipped from the flow" do
      eligibility.had_leadership_position = false
      expect(helper.admin_eligibility_answers(eligibility)).to include([I18n.t("student_loans.admin.had_leadership_position"), "No"])
      expect(helper.admin_eligibility_answers(eligibility)).to_not include([I18n.t("student_loans.admin.mostly_performed_leadership_duties"), "No"])
    end
  end

  describe "#admin_personal_details" do
    let(:claim) do
      build(
        :claim,
        first_name: "Bruce",
        surname: "Wayne",
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ123456C",
        email_address: "test@email.com",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: Date.new(1901, 1, 1),
      )
    end

    it "includes an array of questions and answers" do
      expected_answers = [
        [I18n.t("admin.teacher_reference_number"), "1234567"],
        [I18n.t("verified_fields.full_name").capitalize, "Bruce Wayne"],
        [I18n.t("verified_fields.date_of_birth").capitalize, "01/01/1901"],
        [I18n.t("admin.national_insurance_number"), "QQ123456C"],
        [I18n.t("verified_fields.address").capitalize, "Flat 1<br>1 Test Road<br>Test Town<br>AB1 2CD"],
        [I18n.t("admin.email_address"), "test@email.com"],
      ]

      expect(helper.admin_personal_details(claim)).to eq expected_answers
    end
  end

  describe "#admin_student_loan_details" do
    let(:claim) do
      build(
        :claim,
        student_loan_plan: :plan_1,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1234),
      )
    end

    it "includes an array of questions and answers" do
      expect(helper.admin_student_loan_details(claim)).to eq([
        [I18n.t("student_loans.admin.student_loan_repayment_amount"), "£1,234.00"],
        [I18n.t("student_loans.admin.student_loan_repayment_plan"), "Plan 1"],
      ])
    end
  end

  describe "#admin_submission_details" do
    let(:claim) { create(:claim, :submitted) }

    it "includes an array of questions and answers" do
      expect(helper.admin_submission_details(claim)).to eq([
        [I18n.t("admin.started_at"), l(claim.created_at)],
        [I18n.t("admin.submitted_at"), l(claim.submitted_at)],
        [I18n.t("admin.check_deadline"), l(claim.check_deadline_date)],
      ])
    end

    context "when the claim is approaching its deadline" do
      let(:claim) { create(:claim, :submitted, submitted_at: 5.weeks.ago) }

      it "always includes the deadline date" do
        expect(helper.admin_submission_details(claim)[2].last).to have_content(l(claim.check_deadline_date))
      end

      it "includes the deadline warning" do
        expect(helper.admin_submission_details(claim)[2].last).to have_selector(".tag--warning")
      end
    end
  end

  describe "#display_school" do
    let(:school) do
      build(:school,
        name: "Bash Street School",
        urn: "1234",
        establishment_number: 4567,
        local_authority: build(:local_authority, code: 123))
    end

    it "shows a school with a link and the DfE number" do
      gias_url = "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{school.urn}"
      expect(helper.display_school(school)).to eq(
        "<a class=\"govuk-link\" href=\"#{gias_url}\">#{school.name}</a> <span class=\"govuk-body-s\">(#{school.dfe_number})</span>"
      )
    end
  end

  describe "#check_deadline_warning" do
    subject { helper.check_deadline_warning(claim) }
    before { travel_to Time.zone.local(2019, 10, 11, 7, 0, 0) }
    after { travel_back }

    context "when a claim is approaching it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 5.weeks.ago) }

      it { is_expected.to have_content("7 days") }
      it { is_expected.to have_selector(".tag--warning") }
    end

    context "when a claim has passed it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 10.weeks.ago) }

      it { is_expected.to have_content("-28 days") }
      it { is_expected.to have_selector(".tag--alert") }
    end

    context "when a claim is not near it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 1.day.ago) }

      it { is_expected.to be_nil }
    end
  end
end
