require "rails_helper"

RSpec.feature "Admin checking a claim with matching details" do
  scenario "service operator can check a claim with matching details" do
    claim = create(:claim, :submitted, policy: StudentLoans)
    claim_with_matching_details = create(:claim, :submitted, teacher_reference_number: claim.teacher_reference_number)

    sign_in_as_service_operator

    click_on "View claims"
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Identity confirmation")
    expect(page).to have_content("2. Qualifications")
    expect(page).to have_content("3. Employment")
    expect(page).to have_content("4. Student loan amount")
    expect(page).to have_content("5. Matching details")
    expect(page).to have_content("6. Decision")

    click_on I18n.t("admin.tasks.matching_details")

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.matching_details"))
    expect(page).to have_content(claim_with_matching_details.reference)
    expect(page).to have_content("Teacher reference number")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "matching_details").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "Everything matches"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
  end
end
