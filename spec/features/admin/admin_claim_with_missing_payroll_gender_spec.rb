require "rails_helper"

RSpec.feature "Admin checking a claim missing a payroll gender" do
  before do
    create(:journey_configuration, :student_loans)
    disable_claim_qa_flagging
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "service operator can add a payroll gender as part of the checking process" do
    claim = create(:claim, :submitted, policy: Policies::StudentLoans, payroll_gender: :dont_know)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Identity confirmation")
    expect(page).to have_content("2. Qualifications")
    expect(page).to have_content("3. Census subjects taught")
    expect(page).to have_content("4. Employment")
    expect(page).to have_content("5. Student loan amount")
    expect(page).to have_content("6. Payroll gender")
    expect(page).to have_content("7. Decision")

    click_on I18n.t("admin.tasks.payroll_gender.title")

    expect(page).to have_content("How is the claimant’s gender recorded for payroll purposes?")
    click_on "Save and continue"

    expect(page).to have_content("You must select a gender that will be passed to HMRC")
    choose "Female"
    click_on "Save and continue"

    expect(claim.reload.payroll_gender).to eq("female")
    expect(claim.tasks.find_by!(name: "payroll_gender").passed?).to eq(true)
    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  scenario "with a policy where payroll gender is the last task" do
    irp_claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      payroll_gender: :dont_know
    )

    fe_claim = create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      payroll_gender: :dont_know
    )

    visit admin_claim_tasks_path(irp_claim)
    click_on "How is the claimant’s gender recorded for payroll purposes?"

    choose "Male"
    click_on "Save and continue"

    expect(page).to have_content("Claim decision")

    visit admin_claim_tasks_path(fe_claim)

    click_on "How is the claimant’s gender recorded for payroll purposes?"

    choose "Male"
    click_on "Save and continue"

    expect(page).to have_content("Claim decision")
  end
end
