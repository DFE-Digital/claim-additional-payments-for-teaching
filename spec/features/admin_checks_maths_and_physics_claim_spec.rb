require "rails_helper"

RSpec.feature "Admin checking a Maths & Physics claim" do
  context "without GOV.UK Verify" do
    let!(:claim) { create(:claim, :submitted, policy: MathsAndPhysics) }

    before { @signed_in_user = sign_in_as_service_operator }

    scenario "service operator checks and approves a Maths & Physics claim" do
      visit admin_claims_path
      find("a[href='#{admin_claim_tasks_path(claim)}']").click

      expect(page).to have_content("1. Identity confirmation")
      expect(page).to have_content("2. Qualifications")
      expect(page).to have_content("3. Employment")
      expect(page).to have_content("4. Decision")

      click_on I18n.t("admin.tasks.identity_confirmation")

      expect(page).to have_content("Did #{claim.full_name} submit the claim?")

      choose "Yes"
      click_on "Save and continue"

      expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

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
  end

  context "with GOV.UK Verify" do
    let!(:claim) { create(:claim, :verified, :submitted, policy: MathsAndPhysics) }

    before { @signed_in_user = sign_in_as_service_operator }

    scenario "service operator checks and approves a Maths & Physics claim" do
      visit admin_claims_path
      find("a[href='#{admin_claim_tasks_path(claim)}']").click

      expect(page).to have_content("1. Identity confirmation")
      expect(page).to have_content("2. Qualifications")
      expect(page).to have_content("3. Employment")
      expect(page).to have_content("4. Decision")

      click_on I18n.t("admin.tasks.identity_confirmation")

      expect(page).to have_content("Do our records for this teacher match the above name and date of birth from this claim?")

      choose "Yes"
      click_on "Save and continue"

      expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

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
  end
end
