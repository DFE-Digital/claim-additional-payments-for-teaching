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

  describe "#identity_confirmation_task_claim_verifier_match_status_tag" do
    subject(:identity_confirmation_task_claim_verifier_match_status_tag) { helper.identity_confirmation_task_claim_verifier_match_status_tag(claim) }

    let(:claim) do
      build(
        :claim,
        tasks: claim_tasks
      )
    end

    context "without task" do
      let(:claim_tasks) { [] }

      it "returns unverified task status tag" do
        expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Unverified")
        expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
        expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--grey")
      end
    end

    context "with task" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: task_claim_verifier_match,
            name: "identity_confirmation",
            passed: true
          )
        ]
      end

      context "with task claim verifier match nil" do
        let(:task_claim_verifier_match) { nil }

        it "returns unverified task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Unverified")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--grey")
        end
      end

      context "with task claim verifier match all" do
        let(:task_claim_verifier_match) { :all }

        it "returns full match task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Full match")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns full match task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Partial match")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--yellow")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns no match task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("No match")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--red")
        end
      end
    end
  end

  describe "#task_status_tag" do
    subject(:task_status_tag) { helper.task_status_tag(claim, "employment") }

    let(:claim) do
      build(
        :claim,
        tasks: claim_tasks
      )
    end

    context "without task" do
      let(:claim_tasks) { [] }

      it "returns incomplete task status tag" do
        expect(task_status_tag).to match("Incomplete")
        expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
        expect(task_status_tag).to match("govuk-tag--grey")
      end
    end

    context "with task passed true" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: task_claim_verifier_match,
            name: "employment",
            passed: true
          )
        ]
      end

      context "with task claim verifier match nil" do
        let(:task_claim_verifier_match) { nil }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-green")
        end
      end

      context "with task claim verifier match all" do
        let(:task_claim_verifier_match) { :all }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-green")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-green")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-green")
        end
      end
    end

    context "with task passed false" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: task_claim_verifier_match,
            name: "employment",
            passed: false
          )
        ]
      end

      context "with task claim verifier match nil" do
        let(:task_claim_verifier_match) { nil }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-red")
        end
      end

      context "with task claim verifier match all" do
        let(:task_claim_verifier_match) { :all }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-red")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-red")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--strong-red")
        end
      end
    end

    context "with task passed nil" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: task_claim_verifier_match,
            name: "employment",
            passed: nil
          )
        ]
      end

      context "with task claim verifier matched all" do
        let(:task_claim_verifier_match) { :all }

        it "returns full match status tag" do
          expect(task_status_tag).to match("Full match")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier matched any" do
        let(:task_claim_verifier_match) { :any }

        it "returns partial match status tag" do
          expect(task_status_tag).to match("Partial match")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--yellow")
        end
      end

      context "with task claim verifier matched none" do
        let(:task_claim_verifier_match) { :none }

        it "returns no match status tag" do
          expect(task_status_tag).to match("No match")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--red")
        end
      end
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

  describe "#payroll_run_status" do
    it "returns a payroll status where a claim hasn't gone through payroll" do
      claim = create(:claim, :approved)

      expect(payroll_run_status(claim)).to eq "Awaiting payroll"
    end

    it "returns a payroll status where a claim has gone through payroll" do
      claim = create(:claim, :approved)
      create(:payment, claims: [claim])
      freeze_time do
        expect(payroll_run_status(claim)).to include(Time.zone.now.strftime("%B %Y"))
        expect(payroll_run_status(claim)).to include(admin_payroll_run_path(claim.payment.payroll_run))
      end
    end
  end
end
