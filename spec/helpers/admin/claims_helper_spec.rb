require "rails_helper"

describe Admin::ClaimsHelper do
  let(:claim_school) { schools(:penistone_grammar_school) }
  let(:current_school) { create(:school, :student_loan_eligible) }

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
        date_of_birth: Date.new(1901, 1, 1)
      )
    end

    it "includes an array of questions and answers" do
      expected_answers = [
        [I18n.t("admin.teacher_reference_number"), "1234567"],
        [I18n.t("govuk_verify_fields.full_name").capitalize, "Bruce Wayne"],
        [I18n.t("govuk_verify_fields.date_of_birth").capitalize, "01/01/1901"],
        [I18n.t("admin.national_insurance_number"), "QQ123456C"],
        [I18n.t("govuk_verify_fields.address").capitalize, "Flat 1<br>1 Test Road<br>Test Town<br>AB1 2CD"],
        [I18n.t("admin.email_address"), "test@email.com"]
      ]

      expect(helper.admin_personal_details(claim)).to eq expected_answers
    end

    context "when a claim has had personal data deleted" do
      let(:claim) { build(:claim, :rejected, :personal_data_removed, teacher_reference_number: "1234567", email_address: "test@email.com") }

      it "returns the expected strings" do
        expected_answers = [
          [I18n.t("admin.teacher_reference_number"), "1234567"],
          [I18n.t("govuk_verify_fields.full_name").capitalize, helper.personal_data_removed_text],
          [I18n.t("govuk_verify_fields.date_of_birth").capitalize, helper.personal_data_removed_text],
          [I18n.t("admin.national_insurance_number"), helper.personal_data_removed_text],
          [I18n.t("govuk_verify_fields.address").capitalize, helper.personal_data_removed_text],
          [I18n.t("admin.email_address"), "test@email.com"]
        ]

        expect(helper.admin_personal_details(claim)).to eq expected_answers
      end
    end
  end

  describe "#admin_student_loan_details" do
    let(:claim) do
      build(
        :claim,
        student_loan_plan: :plan_1,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1234)
      )
    end

    it "includes an array of questions and answers" do
      expect(helper.admin_student_loan_details(claim)).to eq([
        [I18n.t("student_loans.admin.student_loan_repayment_amount"), "£1,234.00"],
        [I18n.t("student_loans.admin.student_loan_repayment_plan"), "Plan 1"]
      ])
    end
  end

  describe "#admin_submission_details" do
    let(:claim) { create(:claim, :submitted) }

    it "includes an array of questions and answers" do
      expect(helper.admin_submission_details(claim)).to eq([
        [I18n.t("admin.started_at"), l(claim.created_at)],
        [I18n.t("admin.submitted_at"), l(claim.submitted_at)],
        [I18n.t("admin.decision_deadline"), l(claim.decision_deadline_date)]
      ])
    end

    context "when the claim is approaching its deadline" do
      let(:claim) { create(:claim, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago) }

      it "always includes the deadline date" do
        expect(helper.admin_submission_details(claim)[2].last).to have_content(l(claim.decision_deadline_date))
      end

      it "includes the deadline warning" do
        expect(helper.admin_submission_details(claim)[2].last).to have_selector(".tag--information")
      end
    end
  end

  describe "#admin_decision_details" do
    let(:claim) { create(:claim, :submitted) }
    let(:user) { create(:dfe_signin_user) }
    let(:decision) { Decision.create!(claim: claim, created_by: user, result: :approved) }

    it "includes an array of details about the decision" do
      expect(helper.admin_decision_details(decision)).to eq([
        [I18n.t("admin.decision.created_at"), l(decision.created_at)],
        [I18n.t("admin.decision.result"), decision.result.capitalize],
        [I18n.t("admin.decision.created_by"), user.full_name]
      ])
    end

    context "when notes are saved with the decision" do
      let(:decision) { Decision.create!(claim: claim, created_by: user, result: :approved, notes: "abc\nxyz") }

      it "includes the notes" do
        expect(helper.admin_decision_details(decision)).to include([I18n.t("admin.decision.notes"), simple_format(decision.notes, class: "govuk-body")])
      end
    end

    context "when user does not have a name stored" do
      let(:user) { create(:dfe_signin_user, :without_data) }

      it "displays the user ID" do
        user_id_details = helper.admin_decision_details(decision).last
        expect(user_id_details[0]).to eq(I18n.t("admin.decision.created_by"))
        expect(user_id_details[1]).to match("Unknown user")
        expect(user_id_details[1]).to match("DfE Sign-in ID - #{user.dfe_sign_in_id}")
      end
    end
  end

  describe "#decision_deadline_warning" do
    subject { helper.decision_deadline_warning(claim) }
    before { travel_to Time.zone.local(2019, 10, 11, 7, 0, 0) }
    after { travel_back }

    context "when a claim is approaching it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago) }

      it { is_expected.to have_content("7 days") }
      it { is_expected.to have_selector(".tag--information") }
    end

    context "when a claim has passed it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: (Claim::DECISION_DEADLINE + 4.weeks).ago) }

      it { is_expected.to have_content("-28 days") }
      it { is_expected.to have_selector(".tag--alert") }
    end

    context "when a claim is not near it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 1.day.ago) }

      it { is_expected.to be_nil }
    end
  end

  describe "#id_verification_status" do
    it "reports a claim that as having been GOV.UK Verified" do
      verified_claim = build(:claim, :verified)

      expect(id_verification_status(verified_claim)).to eq "GOV.UK Verify"
    end

    it "returns a warning tag for an unverified claim" do
      verified_claim = build(:claim, :unverified)

      expect(id_verification_status(verified_claim)).to have_content "Unverified"
      expect(id_verification_status(verified_claim)).to have_selector(".tag--information")
    end
  end

  describe "#matching_attributes" do
    let(:first_claim) {
      build(
        :claim,
        teacher_reference_number: "0902344",
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        building_society_roll_number: "123456789/ABCD"
      )
    }
    let(:second_claim) {
      build(
        :claim,
        :submitted,
        teacher_reference_number: first_claim.teacher_reference_number,
        national_insurance_number: first_claim.national_insurance_number,
        bank_account_number: first_claim.bank_account_number,
        bank_sort_code: first_claim.bank_sort_code,
        building_society_roll_number: first_claim.building_society_roll_number
      )
    }
    subject { helper.matching_attributes(first_claim, second_claim) }

    it "returns the humanised names of the matching attributes" do
      expect(subject).to eq(["Bank account number", "Bank sort code", "Building society roll number", "National insurance number", "Teacher reference number"])
    end

    it "does not consider a blank building society roll number to be a match" do
      [first_claim, second_claim].each { |claim| claim.building_society_roll_number = "" }
      expect(subject).to eq(["Bank account number", "Bank sort code", "National insurance number", "Teacher reference number"])
    end
  end

  describe "#task_status_tag" do
    let(:claim) { build(:claim) }
    let(:task_status_tag) { helper.task_status_tag(claim, "employment") }

    it "returns a passed tag if the task has been marked as passed" do
      claim.tasks << build(:task, name: "employment", passed: true, claim: claim)

      expect(task_status_tag).to match("Passed")
      expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
      expect(task_status_tag).to_not match("govuk-tag--inactive")
    end

    it "returns a failed tag if the task has been marked as failed" do
      claim.tasks << build(:task, name: "employment", passed: false, claim: claim)

      expect(task_status_tag).to match("Failed")
      expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
      expect(task_status_tag).to_not match("govuk-tag--inactive")
    end

    it "returns an incomplete tag if the task has not been done" do
      claim.tasks = []

      expect(task_status_tag).to match("Incomplete")
      expect(task_status_tag).to match("govuk-tag app-task-list__task-completed govuk-tag--inactive")
    end
  end

  describe "#claim_summary_heading" do
    context "when the claim has a decision" do
      it "returns the reference field and the decision result" do
        claim = create(:claim, :approved, reference: "1")
        result = helper.claim_summary_heading(claim)
        expect(result).to eql("1 – Approved")
      end
    end

    context "when the claim does not have a decision" do
      it "returns the reference field" do
        claim = create(:claim, reference: "1")
        result = helper.claim_summary_heading(claim)
        expect(result).to eql("1")
      end
    end
  end
end
