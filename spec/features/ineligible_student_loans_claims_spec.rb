require "rails_helper"

RSpec.feature "Ineligible Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
  let(:imported_slc_data) { create(:student_loans_data, nino: "PX321499A", date_of_birth: "28/2/1988", plan_type_of_deduction: 1, amount: 0) }

  scenario "qualified before the first eligible QTS year" do
    policy_configuration.update!(current_academic_year: "2025/2026")

    visit new_claim_path(StudentLoans.routing_name)
    skip_tid
    choose_qts_year(:before_cut_off_date)
    claim = Claim.by_policy(StudentLoans).order(:created_at).last

    expect(claim.eligibility.reload.qts_award_year).to eql("before_cut_off_date")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training between the start of the 2014 to 2015 academic year and the end of the 2020 to 2021 academic year.")

    # Check we can go back and change the answer
    visit claim_path(StudentLoans.routing_name, "qts-year")
    expect(page).to have_current_path("/#{StudentLoans.routing_name}/qts-year")

    choose_qts_year

    expect(page).to have_current_path("/#{StudentLoans.routing_name}/claim-school")
  end

  scenario "chooses an ineligible claim school" do
    claim = start_student_loans_claim
    choose_school ineligible_school

    expect(claim.eligibility.reload.claim_school).to eq ineligible_school
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("#{ineligible_school.name} is not an eligible school.")
  end

  scenario "chooses an ineligible current school" do
    start_student_loans_claim

    choose_school school
    choose_subjects_taught

    choose_still_teaching "Yes, at another school"

    choose_school ineligible_school

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("#{ineligible_school.name}, where you are currently employed to teach, is not a state-funded secondary school.")
  end

  scenario "no longer teaching" do
    claim = start_student_loans_claim
    choose_school school
    choose_subjects_taught

    choose_still_teaching "No"

    expect(claim.eligibility.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you’re still employed to teach at a state-funded secondary school.")
  end

  scenario "did not teach an eligible subject" do
    claim = start_student_loans_claim
    choose_school school

    choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
    click_on "Continue"

    expect(claim.eligibility.reload.taught_eligible_subjects?).to eq(false)
    expect(page).to have_text("You did not select an eligible subject")
    expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{StudentLoans.current_financial_year}:")
  end

  scenario "was in a leadership position and performed leadership duties for more than half of their time" do
    claim = start_student_loans_claim
    choose_school school
    check "Biology"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    choose "Yes"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.mostly_performed_leadership_duties?).to eq(true)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between #{StudentLoans.current_financial_year}.")
  end

  scenario "claimant made zero student loan repayments" do
    imported_slc_data

    claim = start_student_loans_claim
    choose_school school
    expect(claim.eligibility.reload.claim_school).to eql school
    expect(page).to have_text(subjects_taught_question(school_name: school.name))

    check "Physics"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"

    click_on "Continue"

    click_on "Continue"

    # - Personal details
    fill_in "claim_first_name", with: "Russell"
    fill_in "claim_surname", with: "Wong"

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_text("Your student loan repayment amount is £0.00")
    expect(page).to have_text("you are not eligible to claim back any repayments")
  end

  scenario "claimant can start a fresh claim after being told they are ineligible, by visiting the start page" do
    start_student_loans_claim
    choose_school ineligible_school
    expect(page).to have_text("This school is not eligible")

    visit new_claim_path(StudentLoans.routing_name)

    expect(page).to_not have_content("You have a claim in progress")

    skip_tid

    expect(page).to have_content("When did you complete your initial teacher training (ITT)?")
    expect(page).not_to have_css("input[checked]")
    choose_qts_year

    choose_school school

    expect(page).to have_text(subjects_taught_question(school_name: school.name))
  end
end
