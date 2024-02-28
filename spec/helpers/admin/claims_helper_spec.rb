require "rails_helper"

describe Admin::ClaimsHelper do
  let(:claim_school) { create(:school) }
  let(:current_school) { create(:school, :student_loans_eligible) }

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
        [I18n.t("admin.decision_deadline"), l(claim.decision_deadline_date)],
        [I18n.t("admin.decision_overdue"), I18n.t("admin.decision_overdue_not_applicable")]
      ])
    end

    context "when the claim is approaching its deadline" do
      let(:claim) { create(:claim, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago) }

      it "always includes the deadline date" do
        expect(helper.admin_submission_details(claim)[2].last).to have_content(l(claim.decision_deadline_date))
      end

      it "includes the deadline warning" do
        expect(helper.admin_submission_details(claim)[3].last).to have_selector(".tag--information")
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

    context "when the decision is automated" do
      let(:decision) { create(:decision, :auto_approved, claim: claim) }

      it "includes an array of details about the decision" do
        expect(helper.admin_decision_details(decision)).to eq([
          [I18n.t("admin.decision.created_at"), l(decision.created_at)],
          [I18n.t("admin.decision.result"), decision.result.capitalize],
          [I18n.t("admin.decision.notes"), simple_format(decision.notes, class: "govuk-body")]
        ])
      end
    end
  end

  describe "#decision_deadline_warning" do
    subject { helper.decision_deadline_warning(claim) }
    before { travel_to Time.zone.local(2019, 10, 11, 7, 0, 0) }
    after { travel_back }

    context "when a claim is approaching its deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 11.weeks.ago) }

      it { is_expected.to have_content("7 days") }
      it { is_expected.to have_selector(".tag--information") }
    end

    context "when a claim has passed its deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 16.weeks.ago) }

      it { is_expected.to have_content("-28 days") }
      it { is_expected.to have_selector(".tag--alert") }
    end

    context "when a claim is not near its deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 1.day.ago) }

      it { is_expected.to eq "N/A" }
    end

    context "when a claim is not near its deadline and N/A is not shown" do
      subject { helper.decision_deadline_warning(claim, {na_text: ""}) }
      let(:claim) { build(:claim, :submitted, submitted_at: 1.day.ago) }

      it { is_expected.to eq "" }
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
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Passed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns full match task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Passed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns no match task status tag" do
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("Passed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(identity_confirmation_task_claim_verifier_match_status_tag).to match("govuk-tag--green")
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
          expect(task_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match all" do
        let(:task_claim_verifier_match) { :all }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--green")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns passed task status tag" do
          expect(task_status_tag).to match("Passed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--green")
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
          expect(task_status_tag).to match("govuk-tag--red")
        end
      end

      context "with task claim verifier match all" do
        let(:task_claim_verifier_match) { :all }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--red")
        end
      end

      context "with task claim verifier match any" do
        let(:task_claim_verifier_match) { :any }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--red")
        end
      end

      context "with task claim verifier match none" do
        let(:task_claim_verifier_match) { :none }

        it "returns failed task status tag" do
          expect(task_status_tag).to match("Failed")
          expect(task_status_tag).to match("govuk-tag app-task-list__task-completed")
          expect(task_status_tag).to match("govuk-tag--red")
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

  describe "#status" do
    context "claim submitted but not approved" do
      let(:claim) { create(:claim, :submitted) }

      it "returns a status of Awaiting decision" do
        expect(status(claim)).to eq "Awaiting decision - not on hold"
      end
    end

    context "claim approved and flagged for QA" do
      let(:claim) { create(:claim, :approved, :flagged_for_qa) }

      it "returns a status of Approved awaiting QA" do
        expect(status(claim)).to eq "Approved awaiting QA"
      end
    end

    context "claim held" do
      let(:claim) { create(:claim, :submitted, :held) }

      it "returns a status of Awaiting decision" do
        expect(status(claim)).to eq "Awaiting decision - on hold"
      end
    end

    context "claim approved" do
      it "returns a status of Approved awaiting payroll" do
        claim = create(:claim, :approved)

        expect(status(claim)).to eq "Approved awaiting payroll"
      end
    end

    context "claim rejected" do
      it "returns a status of Rejected" do
        claim = create(:claim, :rejected)

        expect(status(claim)).to eq "Rejected"
      end
    end

    context "claim has been included in a payroll" do
      let(:claim) { create(:claim, :approved) }

      before { create(:payment, claims: [claim]) }

      it "returns a status with a link to the payroll run" do
        freeze_time do
          expect(status(claim)).to eq "Payrolled"
        end
      end
    end
  end

  describe "#claim_status_filters" do
    subject { helper.claim_status_filters }

    it "returns the list of status filters available" do
      is_expected.to eq(described_class::STATUS_FILTERS)
    end
  end

  describe "#index_status_filter" do
    subject { helper.index_status_filter(status) }

    context "when status is blank" do
      let(:status) { "" }

      it { is_expected.to eq("awaiting a decision") }
    end

    context "when status is present" do
      let(:status) { "approved_awaiting_payroll" }

      it "returns a human readable version of the status in lower case" do
        is_expected.to eq("approved awaiting payroll")
      end
    end
  end

  describe "#no_claims" do
    subject { helper.no_claims(status) }

    context "when status is 'approved_awaiting_qa'" do
      let(:status) { "approved_awaiting_qa" }

      it { is_expected.to eq("There are currently no approved claims awaiting QA.") }
    end

    context "when status is 'approved_awaiting_payroll'" do
      let(:status) { "approved_awaiting_payroll" }

      it { is_expected.to eq("There are currently no approved claims awaiting payroll.") }
    end

    context "when status is 'automatically_approved_awaiting_payroll'" do
      let(:status) { "automatically_approved_awaiting_payroll" }

      it { is_expected.to eq("There are currently no automatically approved claims awaiting payroll.") }
    end

    context "when status is 'approved'" do
      let(:status) { "approved" }

      it { is_expected.to eq("There are currently no approved claims.") }
    end

    context "when status is 'rejected'" do
      let(:status) { "rejected" }

      it { is_expected.to eq("There are currently no rejected claims.") }
    end

    context "when status is not present" do
      let(:status) { "" }

      it { is_expected.to eq("There are currently no claims to approve.") }
    end
  end

  describe "#admin_policy_options_provided" do
    context "Eligible for ECP and LUP" do
      let(:claim) { create(:claim, :submitted, :policy_options_provided_with_both, policy: Policies::EarlyCareerPayments) }

      it "returns both polices" do
        answers = [["Early-career payment", "£2,000"], ["Levelling up premium payment", "£2,000"]]

        expect(admin_policy_options_provided(claim)).to match_array answers
      end
    end

    context "Eligible for ECP only" do
      let(:claim) { create(:claim, :submitted, :policy_options_provided_ecp_only, policy: Policies::EarlyCareerPayments) }

      it "returns ECP only" do
        answers = [["Early-career payment", "£2,000"]]

        expect(admin_policy_options_provided(claim)).to match_array answers
      end
    end

    context "Eligible for LUP only" do
      let(:claim) { create(:claim, :submitted, :policy_options_provided_lup_only, policy: LevellingUpPremiumPayments) }

      it "returns LUP only" do
        answers = [["Levelling up premium payment", "£2,000"]]

        expect(admin_policy_options_provided(claim)).to match_array answers
      end
    end

    context "No policy_options_provided (not ECP/LUP claim)" do
      let(:claim) { create(:claim, :submitted) }

      it "returns no options" do
        expect(admin_policy_options_provided(claim)).to match_array []
      end
    end
  end

  describe "#code_msg" do
    context "400 error with bank account" do
      let(:claim) { create(:claim, :submitted, bank_or_building_society: :personal_bank_account) }
      let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 400, body: {}.to_json})) }

      it "returns message with code and bank account" do
        expect(code_msg(bank_account_verification_response, claim)).to eq "Error 400 - HMRC API failure. No checks have been completed on the claimant’s bank account details. Select yes to manually approve the claimant’s bank account details"
      end
    end

    context "429 error with building society" do
      let(:claim) { create(:claim, :submitted, bank_or_building_society: :building_society) }
      let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 429, body: {}.to_json})) }

      it "returns message with code and bank account" do
        expect(code_msg(bank_account_verification_response, claim)).to eq "Error 429 - HMRC API failure. No checks have been completed on the claimant’s building society details. Select yes to manually approve the claimant’s building society details"
      end
    end
  end

  describe "#sort_code_msg" do
    context "sort code correct" do
      let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 200, body: {"sortCodeIsPresentOnEISCD" => "yes"}.to_json})) }

      it "returns correct message" do
        expect(sort_code_msg(bank_account_verification_response)).to eq "Yes - sort code found"
      end
    end

    context "sort code incorrect" do
      let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 200, body: {"sortCodeIsPresentOnEISCD" => "no"}.to_json})) }

      it "returns incorrect message" do
        expect(sort_code_msg(bank_account_verification_response)).to eq "No - sort code not found"
      end
    end
  end

  describe "#account_number_msg" do
    let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 200, body: {"accountExists" => account_exists}.to_json})) }

    context "yes" do
      let(:account_exists) { "yes" }

      it "returns yes message" do
        expect(account_number_msg(bank_account_verification_response)).to eq "Yes - sort code and account number match"
      end
    end

    context "no" do
      let(:account_exists) { "no" }

      it "returns no message" do
        expect(account_number_msg(bank_account_verification_response)).to eq "No - account number not valid for the given sort code"
      end
    end

    context "indeterminate" do
      let(:account_exists) { "indeterminate" }

      it "returns indeterminate message" do
        expect(account_number_msg(bank_account_verification_response)).to eq "Indeterminate - sort code and account number not found"
      end
    end

    context "inapplicable" do
      let(:account_exists) { "inapplicable" }

      it "returns inapplicable message" do
        expect(account_number_msg(bank_account_verification_response)).to eq "Inapplicable - sort code and/or account number failed initial validation, no further checks completed"
      end
    end
  end

  describe "#name_matches_msg" do
    let(:bank_account_verification_response) { Hmrc::BankAccountVerificationResponse.new(OpenStruct.new({code: 200, body: {"nameMatches" => name_matches}.to_json})) }

    context "yes" do
      let(:name_matches) { "yes" }

      it "returns yes message" do
        expect(name_matches_msg(bank_account_verification_response)).to eq "Yes - name matches the account holder name"
      end
    end

    context "partial" do
      let(:name_matches) { "partial" }

      it "returns partial message" do
        expect(name_matches_msg(bank_account_verification_response)).to eq "Partial - After normalisation, the provided name is a close match"
      end
    end

    context "no" do
      let(:name_matches) { "no" }

      it "returns no message" do
        expect(name_matches_msg(bank_account_verification_response)).to eq "No - name does not match the account holder name"
      end
    end

    context "inapplicable" do
      let(:name_matches) { "inapplicable" }

      it "returns inapplicable message" do
        expect(name_matches_msg(bank_account_verification_response)).to eq "Inapplicable - sort code and/or account number failed initial validation, no further checks completed"
      end
    end
  end
end
