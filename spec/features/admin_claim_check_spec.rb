require "rails_helper"

RSpec.feature "Admin checks a claim" do
  let(:user) { create(:dfe_signin_user) }

  context "User is logged in as a service operator" do
    before do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    end

    scenario "User can approve a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted)
        claim_to_approve = submitted_claims.first

        click_on "View claims"

        expect(page).to have_content(claim_to_approve.reference)
        expect(page).to have_content("5 claims awaiting checking")

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        choose "Approve"
        fill_in "Decision notes", with: "Everything matches"
        perform_enqueued_jobs { click_on "Submit" }

        expect(claim_to_approve.check.checked_by).to eq(user)
        expect(claim_to_approve.check.notes).to eq("Everything matches")

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
      submitted_claims = create_list(:claim, 5, :submitted)
      claim_to_reject = submitted_claims.first

      click_on "View claims"

      expect(page).to have_content(claim_to_reject.reference)
      expect(page).to have_content("5 claims awaiting checking")

      find("a[href='#{admin_claim_path(claim_to_reject)}']").click
      choose "Reject"
      fill_in "Decision notes", with: "TRN doesn't exist"
      perform_enqueued_jobs { click_on "Submit" }

      expect(claim_to_reject.check.checked_by).to eq(user)
      expect(claim_to_reject.check.notes).to eq("TRN doesn't exist")

      expect(page).to have_content("Claim has been rejected successfully")
      expect(page).to_not have_content(claim_to_reject.reference)

      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to match("been rejected")
      expect(mail.to).to eq([claim_to_reject.email_address])
      expect(mail.body.raw_source).to match("not been able to approve")
    end

    scenario "User can see existing check details" do
      claim_with_check = create(:claim, :submitted, check: build(:check, result: :approved, notes: "Everything matches"))
      visit admin_claim_path(claim_with_check)

      expect(page).not_to have_button("Submit")
      expect(page).to have_content("Claim decision")
      expect(page).to have_content("Approved")
      expect(page).to have_content(claim_with_check.check.notes)
    end

    context "When the payroll gender is missing" do
      let!(:claim_missing_payroll_gender) { create(:claim, :submitted, payroll_gender: :dont_know) }

      scenario "User is informed that the claim cannot be approved" do
        click_on "View claims"
        find("a[href='#{admin_claim_path(claim_missing_payroll_gender)}']").click

        expect(page).to have_field("Approve", disabled: true)
        expect(page).to have_content("This claim cannot be approved, the payroll gender is missing")
      end
    end

    context "When the claimant has not completed GOV.UK Verify" do
      let!(:claim_without_identity_confirmation) { create(:claim, :unverified) }

      scenario "the service operator should be told the identity hasn't been confirmed" do
        click_on "View claims"
        find("a[href='#{admin_claim_path(claim_without_identity_confirmation)}']").click

        expect(page).to have_content("Identity has not been confirmed")
        expect(page).to have_field("Approve", disabled: true)
      end
    end

    context "with a mixture of policy types" do
      let!(:maths_and_physics_claims) { create_list(:claim, 3, :submitted, policy: MathsAndPhysics) }
      let!(:student_loan_claims) { create_list(:claim, 2, :submitted, policy: StudentLoans) }

      it "shows the policy types on the index page" do
        click_on "View claims"

        expect(page.find("table")).to have_content("Maths and Physics").exactly(3).times
        expect(page.find("table")).to have_content("Student Loans").exactly(2).times
      end

      it "can filter by claim type" do
        click_on "View claims"
        select "Maths and Physics", from: "policy"
        click_on "Go"

        maths_and_physics_claims.each do |c|
          expect(page).to have_content(c.reference)
        end

        student_loan_claims.each do |c|
          expect(page).to_not have_content(c.reference)
        end
      end
    end
  end

  context "User is logged in as a payroll operator or a support user" do
    [AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, AdminSession::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      scenario "User cannot view claims to check" do
        sign_in_to_admin_with_role(role)

        expect(page).to_not have_link(nil, href: admin_claims_path)

        visit admin_claims_path

        expect(page.status_code).to eq(401)
        expect(page).to have_content("Not authorised")
      end
    end
  end
end
