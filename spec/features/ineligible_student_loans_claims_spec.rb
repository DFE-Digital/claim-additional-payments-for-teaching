require "rails_helper"

RSpec.feature "Ineligible Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  scenario "qualified before the first eligible QTS year" do
    policy_configurations(:student_loans).update!(current_academic_year: "2025/2026")

    visit new_claim_path(StudentLoans.routing_name)
    choose_qts_year(:before_cut_off_date)
    claim = Claim.order(:created_at).last

    expect(claim.eligibility.reload.qts_award_year).to eql("before_cut_off_date")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training in or after the academic year 2014 to 2015.")
  end

  scenario "chooses an ineligible claim school" do
    claim = start_student_loans_claim
    choose_school schools(:hampstead_school)

    expect(claim.eligibility.reload.claim_school).to eq schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("Hampstead School is not an eligible school.")
  end

  scenario "chooses an ineligible current school" do
    start_student_loans_claim

    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught

    choose_still_teaching "Yes, at another school"

    fill_in :school_search, with: "Bradford"
    click_on "Search"

    choose "Bradford Grammar School"
    click_on "Continue"

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("Bradford Grammar School, where you are currently employed to teach, is not a state-funded secondary school.")
  end

  scenario "no longer teaching" do
    claim = start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught

    choose_still_teaching "No"

    expect(claim.eligibility.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you’re still employed to teach at a state-funded secondary school.")
  end

  scenario "did not teach an eligible subject" do
    claim = start_student_loans_claim
    choose_school schools(:penistone_grammar_school)

    choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
    click_on "Continue"

    expect(claim.eligibility.reload.taught_eligible_subjects?).to eq(false)
    expect(page).to have_text("You did not select an eligible subject")
    expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{StudentLoans.current_financial_year}:")
  end

  scenario "was in a leadership position and performed leadership duties for more than half of their time" do
    claim = start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
    check "Biology"
    click_on "Continue"

    choose_still_teaching

    choose "Yes"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.mostly_performed_leadership_duties?).to eq(true)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between 6 April 2018 and 5 April 2019.")
  end

  scenario "claimant can start a fresh claim after being told they are ineligible, by visiting the start page" do
    start_student_loans_claim
    choose_school schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")

    visit new_claim_path(StudentLoans.routing_name)

    expect(page).to_not have_content("You have a claim in progress")

    expect(page).to have_content("When did you complete your initial teacher training?")
    expect(page).not_to have_css("input[checked]")
    choose_qts_year

    choose_school schools(:penistone_grammar_school)

    expect(page).to have_text(subjects_taught_question(school_name: schools(:penistone_grammar_school).name))
  end
end
