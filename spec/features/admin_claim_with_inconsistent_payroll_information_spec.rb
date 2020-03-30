require "rails_helper"

RSpec.feature "Admin checking a claim with inconsistent payroll information" do
  let(:personal_details) do
    {
      national_insurance_number: generate(:national_insurance_number),
      teacher_reference_number: generate(:teacher_reference_number),
      date_of_birth: 30.years.ago.to_date,
      student_loan_plan: StudentLoan::PLAN_1,
      email_address: "email@example.com",
      bank_sort_code: "112233",
      bank_account_number: "95928482",
      building_society_roll_number: ""
    }
  end

  before { sign_in_as_service_operator }

  scenario "cannot approve a second claim from an individual whilst the payroll information on the claims is inconsistent" do
    approved_claim = create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823"))
    second_inconsistent_claim = create(:claim, :submitted, personal_details.merge(bank_sort_code: "582939", bank_account_number: "74727752"))

    click_on "View claims"
    find("a[href='#{admin_claim_tasks_path(second_inconsistent_claim)}']").click

    click_on "Approve or reject this claim"

    expect(page).to have_field("Approve", disabled: true)
    expect(page).to have_content("This claim cannot currently be approved because we’re already paying another claim (#{approved_claim.reference}) to this claimant in this payroll month using different payment details. Please speak to a Grade 7.")

    click_on "Amend claim"
    fill_in "Bank sort code", with: approved_claim.bank_sort_code
    fill_in "Bank account number", with: approved_claim.bank_account_number
    fill_in "Change notes", with: "Corrected bank account details"
    click_on "Amend claim"

    expect(second_inconsistent_claim.reload).to be_approvable

    click_on "Approve or reject this claim"

    choose "Approve"
    fill_in "Decision notes", with: "Everything matches"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
  end
end
