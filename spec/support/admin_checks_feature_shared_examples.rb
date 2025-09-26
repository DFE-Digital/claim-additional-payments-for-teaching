require "rails_helper"

# The following is moved from an old spec. Haven't taken the effort to refactor it here.
RSpec.shared_examples "Admin Checks" do |policy|
  let!(:claim) {
    if policy == Policies::FurtherEducationPayments
      create(
        :claim,
        :submitted,
        :with_student_loan,
        :with_onelogin_idv_data,
        policy: policy,
        eligibility: build(:"#{policy.to_s.underscore}_eligibility", :eligible, :verified),
        academic_year: AcademicYear.new(2024),
        onelogin_idv_at: 10.minutes.ago
        academic_year: AcademicYear.new(2024)
      )
    else
      create(
        :claim,
        :submitted,
        :with_student_loan,
        policy: policy,
        eligibility: build(:"#{policy.to_s.underscore}_eligibility", :eligible)
      )
    end
  }

  before do
    @signed_in_user = sign_in_as_service_operator
    create(:task, :automated, :passed, name: "student_loan_plan", claim:)
  end

  def targeted_retention_incentive_claim_checking_steps
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.identity_confirmation.title")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next:Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.qualifications.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_content("ITT subject")
    expect(page).to have_content(claim.eligibility.eligible_itt_subject.humanize)
    expect(page).to have_link("Next:Census subjects taught")
    expect(page).to have_link("Previous:Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subject Mathematics")
    expect(page).to have_link("Next:Employment")
    expect(page).to have_link("Previous:Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next:Student loan plan")
    expect(page).to have_link("Previous:Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Student loan plan")
    expect(page).to have_link("Next:Decision")
    expect(page).to have_link("Previous:Employment")
    expect(page).to have_content("Passed")
    expect(page).not_to have_button("Save and continue")

    click_link "Next:Decision"

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous:Student loan plan")

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

    click_on I18n.t("admin.tasks.identity_confirmation.title")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next:Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.qualifications.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_content("ITT subject")
    expect(page).to have_content(claim.eligibility.eligible_itt_subject.humanize)
    expect(page).to have_link("Next:Induction confirmation")
    expect(page).to have_link("Previous:Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.induction_confirmation.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_link("Next:Census subjects taught")
    expect(page).to have_link("Previous:Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "induction_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subject Mathematics")
    expect(page).to have_link("Next:Employment")
    expect(page).to have_link("Previous:Induction confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next:Student loan plan")
    expect(page).to have_link("Previous:Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Student loan plan")
    expect(page).to have_link("Next:Decision")
    expect(page).to have_link("Previous:Employment")
    expect(page).to have_content("Passed")
    expect(page).not_to have_button("Save and continue")

    click_link "Next:Decision"

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous:Student loan plan")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  def tslr_claim_checking_steps
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.identity_confirmation.title")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next:Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.qualifications.title"))
    expect(page).to have_content("Award year")
    expect(page).to have_content(I18n.t("student_loans.answers.qts_award_years.#{claim.eligibility.qts_award_year}", year: Policies::StudentLoans.first_eligible_qts_award_year(claim.academic_year).to_s(:long)))
    expect(page).to have_link("Next:Census subjects taught")
    expect(page).to have_link("Previous:Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subjects taught Physics")
    expect(page).to have_link("Next:Employment")
    expect(page).to have_link("Previous:Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next:Student loan amount")
    expect(page).to have_link("Previous:Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.student_loan_amount.title"))
    expect(page).to have_content("£1,000.00")
    expect(page).to have_content("Plan 1")
    expect(page).to have_link("Next:Decision")
    expect(page).to have_link("Previous:Employment")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "student_loan_amount").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous:Student loan amount")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  def fe_claim_checking_steps
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.one_login_identity.title")

    expect(page).to have_link("Next:Provider verification")
    expect(page).not_to have_link("Previous")

    click_link("Next:Provider verification")

    expect(page).to have_content(I18n.t("#{claim.policy.to_s.underscore}.admin.task_questions.provider_verification.title"))
    expect(page).to have_link("Next:Student loan plan")
    expect(page).to have_link("Previous:Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "provider_verification").passed?).to eq(true)

    expect(page).to have_content("Student loan plan")
    expect(page).to have_content("Passed")
    expect(page).not_to have_button("Save and continue")
    expect(page).to have_link("Next:Decision")
    expect(page).to have_link("Previous:Provider verification")

    click_link "Next:Decision"

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous:Student loan plan")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  def qa_approval_steps
    expect(page).to have_content("This claim has been marked for a quality assurance review")
    expect(page).to have_content("Quality assurance decision")
    expect(claim.reload).to be_qa_required

    click_on "Approve or reject quality assurance of this claim"

    choose "Approve"
    fill_in "Decision notes", with: "QA passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(page).not_to have_content("This claim has been marked for a quality assurance review")
    expect(claim.reload).to be_qa_completed
    expect(claim.previous_decision).to be_undone
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end

  def claim_checking_steps(policy)
    if policy == Policies::TargetedRetentionIncentivePayments
      targeted_retention_incentive_claim_checking_steps
    elsif policy == Policies::EarlyCareerPayments
      ecp_claim_checking_steps
    elsif policy == Policies::StudentLoans
      tslr_claim_checking_steps
    elsif policy == Policies::FurtherEducationPayments
      fe_claim_checking_steps
    else
      raise "Unimplemented policy: #{policy}"
    end
  end

  policy_name = policy.to_s.underscore.humanize.titleize

  scenario "service operator checks and approves a #{policy_name} claim" do
    disable_claim_qa_flagging
    claim_checking_steps(policy)
  end

  scenario "service operator QAs a #{policy_name} claim", if: policy::APPROVED_MIN_QA_THRESHOLD.positive? do
    claim_checking_steps(policy)
    qa_approval_steps
  end
end
