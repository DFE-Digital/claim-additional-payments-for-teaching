require "rails_helper"

RSpec.feature "Admin checking a claim with matching details" do
  before do
    create(:journey_configuration, :student_loans)
    disable_claim_qa_flagging
    sign_in_as_service_operator
  end

  scenario "service operator can check a claim with matching details" do
    claim = create(:claim, :submitted, policy: Policies::StudentLoans)
    claim_with_matching_details = create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number})

    click_on "Claims"
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Identity confirmation")
    expect(page).to have_content("2. Qualifications")
    expect(page).to have_content("3. Census subjects taught")
    expect(page).to have_content("4. Employment")
    expect(page).to have_content("5. Student loan amount")
    expect(page).to have_content("6. Matching details")
    expect(page).to have_content("7. Decision")

    click_on I18n.t("admin.tasks.matching_details.title")

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.matching_details.title"))
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

  scenario "partial matching details" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::StudentLoans,
      bank_sort_code: "123456"
    )

    # Matching claim
    create(
      :claim,
      :submitted,
      bank_sort_code: "123456",
      eligibility_attributes: {
        teacher_reference_number: claim.eligibility.teacher_reference_number
      }
    )

    visit admin_claim_tasks_path(claim)

    click_on "Multiple claims"

    within "#claims-with-matches" do
      expect(page).to have_content "Teacher reference number"
      # Bank sort code on it's own isn't enough to trigger a match,
      # so shouldn't be displayed
      expect(page).not_to have_content "Bank sort code"
    end
  end

  scenario "admin forgets to select an option" do
    claim = create(:claim, :submitted, policy: Policies::StudentLoans)
    create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number})

    click_on "Claims"
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.matching_details.title")

    click_on "Save and continue"
  end
end
