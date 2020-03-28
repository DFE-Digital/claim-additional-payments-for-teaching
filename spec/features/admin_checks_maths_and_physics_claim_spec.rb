require "rails_helper"

RSpec.feature "Admin checking a Maths & Physics claim" do
  let!(:claim) { create(:claim, :submitted, policy: MathsAndPhysics) }

  before { @signed_in_user = sign_in_as_service_operator }

  scenario "service operator checks and approves a Maths & Physics claim" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")
    expect(page).to have_content("3. Decision")

    click_on "Check qualification information"

    expect(page).to have_content(I18n.t("maths_and_physics.admin.task_questions.qualifications"))
    expect(page).to have_content("Award year")
    expect(page).to have_content(claim.eligibility.qts_award_year_answer)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("maths_and_physics.admin.task_questions.employment"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  scenario "service operator can check a claim with matching details" do
    claim_with_matching_details = create(:claim, :submitted,
      teacher_reference_number: claim.teacher_reference_number,
      policy: MathsAndPhysics)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")
    expect(page).to have_content("3. Matching details")
    expect(page).to have_content("4. Decision")

    click_on I18n.t("admin.tasks.matching_details")

    expect(page).to have_content(I18n.t("maths_and_physics.admin.task_questions.matching_details"))
    expect(page).to have_content(claim_with_matching_details.reference)
    expect(page).to have_content("Teacher reference number")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "matching_details").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
  end

  scenario "service operator sees an error if they don't choose a Yes/No option on a check" do
    claim = create(:claim, :submitted, policy: MathsAndPhysics)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on "Check qualification information"

    click_on "Save and continue"

    expect(page).to have_content("You must select ‘Yes’ or ‘No’")
    expect(claim.tasks.find_by(name: "qualifications")).to be_nil
  end
end
