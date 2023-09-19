require "rails_helper"

# The following is moved from an old spec. Haven't taken the effort to refactor it here.
RSpec.shared_examples "Admin Checks for Early Career Payments and Levelling Up Premium Payments" do |policy|
  let!(:policy_configuration) { create(:policy_configuration, policy.to_s.underscore) }
  let!(:claim) {
    create(
      :claim,
      :submitted,
      :with_student_loan,
      policy: policy,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  before do
    @signed_in_user = sign_in_as_service_operator
  end

  def lup_claim_checking_steps
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.identity_confirmation")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next: Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.qualifications.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_content("ITT subject")
    expect(page).to have_content(claim.eligibility.eligible_itt_subject.humanize)
    expect(page).to have_link("Next: Census subjects taught")
    expect(page).to have_link("Previous: Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subject Mathematics")
    expect(page).to have_link("Next: Employment")
    expect(page).to have_link("Previous: Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next: Decision")
    expect(page).to have_link("Previous: Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous: Employment")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  def ecp_claim_checking_steps
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.identity_confirmation")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next: Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.qualifications.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_content("ITT subject")
    expect(page).to have_content(claim.eligibility.eligible_itt_subject.humanize)
    expect(page).to have_link("Next: Induction confirmation")
    expect(page).to have_link("Previous: Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.induction_confirmation.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_link("Next: Census subjects taught")
    expect(page).to have_link("Previous: Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "induction_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subject Mathematics")
    expect(page).to have_link("Next: Employment")
    expect(page).to have_link("Previous: Induction confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next: Decision")
    expect(page).to have_link("Previous: Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous: Employment")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  if policy == LevellingUpPremiumPayments
    scenario "service operator checks and approves a Levelling Up Premium Payments claim" do
      lup_claim_checking_steps
    end
  elsif policy == EarlyCareerPayments
    scenario "service operator checks and approves a Early Career Payments claim" do
      ecp_claim_checking_steps
    end
  else
    raise "Unimplemented policy: #{policy}"
  end
end
