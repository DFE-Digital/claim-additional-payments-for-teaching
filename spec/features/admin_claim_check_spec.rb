require "rails_helper"

RSpec.feature "Admin checks a claim" do
  let(:user) { create(:dfe_signin_user) }

  context "User is logged in as a service operator" do
    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    end

    scenario "User can approve a claim" do
      freeze_time do
        stub_geckoboard_dataset_update
        submitted_claims = create_list(:claim, 5, :submitted, policy: StudentLoans)
        claim_to_approve = submitted_claims.first

        click_on "View claims"

        expect(page).to have_content(claim_to_approve.reference)
        expect(page).to have_content("5 claims awaiting a decision")

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        choose "Approve"
        fill_in "Decision notes", with: "Everything matches"
        perform_enqueued_jobs { click_on "Confirm decision" }

        expect(claim_to_approve.decision.created_by).to eq(user)
        expect(claim_to_approve.decision.notes).to eq("Everything matches")

        expect(page).to have_content("Claim has been approved successfully")
        expect(page).to_not have_content(claim_to_approve.reference)

        expect(ActionMailer::Base.deliveries.count).to eq(1)

        mail = ActionMailer::Base.deliveries.first

        expect(mail.subject).to match("been approved")
        expect(mail.to).to eq([claim_to_approve.email_address])
        expect(mail.body.raw_source).to match("been approved")
      end
    end

    scenario "they can reject a claim" do
      stub_geckoboard_dataset_update
      submitted_claims = create_list(:claim, 5, :submitted)
      claim_to_reject = submitted_claims.first

      click_on "View claims"

      expect(page).to have_content(claim_to_reject.reference)
      expect(page).to have_content("5 claims awaiting a decision")

      find("a[href='#{admin_claim_path(claim_to_reject)}']").click
      choose "Reject"
      fill_in "Decision notes", with: "TRN doesn't exist"
      perform_enqueued_jobs { click_on "Confirm decision" }

      expect(claim_to_reject.decision.created_by).to eq(user)
      expect(claim_to_reject.decision.notes).to eq("TRN doesn't exist")

      expect(page).to have_content("Claim has been rejected successfully")
      expect(page).to_not have_content(claim_to_reject.reference)

      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to match("been rejected")
      expect(mail.to).to eq([claim_to_reject.email_address])
      expect(mail.body.raw_source).to match("not been able to approve")
    end

    scenario "User can see completed tasks" do
      ten_minutes_ago = 10.minutes.ago
      checking_user = create(:dfe_signin_user, given_name: "Fred", family_name: "Smith")
      qualification_task = build(:task, name: "qualifications", created_by: checking_user, created_at: ten_minutes_ago)
      claim_with_tasks = create(:claim, :submitted, tasks: [qualification_task, build(:task, name: "employment")])
      visit admin_claim_tasks_path(claim_with_tasks)

      expect(page).to have_content("Check qualification information Completed")
      expect(page).to have_content("Check employment information Completed")
      expect(page).to have_link("Approve or reject this claim", href: new_admin_claim_decision_path(claim_with_tasks))

      click_on "Check qualification information"
      expect(page).to have_content("Performed by #{checking_user.full_name}")
      expect(page).to have_content(I18n.l(ten_minutes_ago))
      expect(page).not_to have_button("Complete qualifications check and continue")
    end

    scenario "User can see existing decision details" do
      claim_with_decision = create(:claim, :submitted, decisions: [build(:decision, result: :approved, notes: "Everything matches")])
      visit admin_claim_path(claim_with_decision)

      expect(page).not_to have_button("Confirm decision")
      expect(page).to have_content("Claim decision")
      expect(page).to have_content("Approved")
      expect(page).to have_content(claim_with_decision.decision.notes)
      expect(page).to have_content("Created by")
      expect(page).to have_content(user.full_name)
    end

    context "when the service operator completes the last checking task" do
      context "and the payroll gender is missing" do
        let!(:claim) { create(:claim, :submitted, payroll_gender: :dont_know) }

        scenario "User is informed that the claim cannot be approved" do
          perform_last_task(claim)

          expect(page).to have_field("Approve", disabled: true)
          expect(page).to have_content(I18n.t("admin.unknown_payroll_gender_preventing_approval_message"))
        end
      end

      context "and the claimant has another approved claim in the same payroll window, with inconsistent personal details" do
        let(:personal_details) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            date_of_birth: 30.years.ago.to_date,
            student_loan_plan: StudentLoan::PLAN_1,
            email_address: "email@example.com",
            bank_sort_code: "112233",
            bank_account_number: "95928482",
            building_society_roll_number: nil
          }
        end
        let!(:approved_claim) { create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823")) }
        let!(:claim) { create(:claim, :submitted, personal_details.merge(bank_sort_code: "582939", bank_account_number: "74727752")) }

        scenario "User is informed that the claim cannot be approved" do
          perform_last_task(claim)

          expect(page).to have_field("Approve", disabled: true)
          expect(page).to have_content("This claim cannot currently be approved because we’re already paying another claim (#{approved_claim.reference}) to this claimant in this payroll month using different payment details. Please speak to a Grade 7.")
        end
      end

      context "and the claimant has not completed GOV.UK Verify" do
        let!(:claim) { create(:claim, :unverified) }

        scenario "the service operator is told the identity hasn't been confirmed and can approve the claim" do
          perform_last_task(claim)

          expect(page).to have_content("The claimant did not complete GOV.UK Verify")
          expect(page).to have_content(claim.school.phone_number)

          choose "Approve"
          fill_in "Decision notes", with: "Identity confirmed via phone call"
          click_on "Confirm decision"

          expect(claim.decision.created_by).to eq(user)
          expect(claim.decision.notes).to eq("Identity confirmed via phone call")
        end
      end

      def perform_last_task(claim)
        applicable_task_names = ClaimCheckingTasks.new(claim).applicable_task_names
        visit admin_claim_task_path(claim, name: applicable_task_names.last)
        find("input[type='submit']").click
      end
    end
  end

  context "User is logged in as a payroll operator or a support user" do
    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      scenario "User cannot view claims" do
        sign_in_to_admin_with_role(role)

        expect(page).to_not have_link(nil, href: admin_claims_path)

        visit admin_claims_path

        expect(page.status_code).to eq(401)
        expect(page).to have_content("Not authorised")
      end
    end
  end
end
