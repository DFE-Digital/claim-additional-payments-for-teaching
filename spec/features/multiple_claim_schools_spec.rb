require "rails_helper"

RSpec.feature "Applicant worked at multiple schools" do
  include StudentLoansHelper

  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }
  let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
  let!(:eligible_school) { create(:school, :student_loans_eligible) }
  let!(:claim) { start_student_loans_claim }

  scenario "first claim school is ineligible and subsequent school is eligible" do
    choose_school ineligible_school

    expect(claim.eligibility.reload.claim_school).to eq ineligible_school
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("#{ineligible_school.name} is not an eligible school.")

    click_on "Enter another school"

    expect(page).to_not have_css("input[value=\"Hampstead School\"]")
    expect(page).to have_text(claim_school_question(additional_school: true))
    expect(page).to_not have_text("If you taught at multiple schools")

    choose_school eligible_school
    expect(claim.eligibility.reload.claim_school).to eq eligible_school

    expect(page).to have_text(subjects_taught_question(school_name: eligible_school.name))
  end

  scenario "first claim school is ineligible and subsequent school is ineligible too" do
    another_ineligible_school = create(:school, :student_loans_ineligible)
    choose_school ineligible_school
    click_on "Enter another school"

    choose_school another_ineligible_school
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("#{another_ineligible_school.name} is not an eligible school.")

    click_on "I've tried all of my schools"

    expect(page).to have_text("You're not eligible for this payment")
  end

  scenario "didn't teach eligible subjects, but taught eligible subjects at a different eligible school" do
    choose_school eligible_school

    choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
    click_on "Continue"

    expect(page).to have_text("You did not select an eligible subject")
    expect(page).to have_text("You did not teach an eligible subject at #{eligible_school.name}.")

    click_on "Enter another school"

    expect(page).to_not have_css("input[value=\"#{eligible_school.name}\"]")
    expect(page).to have_text(claim_school_question(additional_school: true))

    choose_school eligible_school

    check I18n.t("student_loans.questions.eligible_subjects.biology_taught")
    check I18n.t("student_loans.questions.eligible_subjects.physics_taught")
    click_on "Continue"

    expect(claim.eligibility.reload.taught_eligible_subjects).to eq(true)
    expect(claim.eligibility.biology_taught).to eq(true)
    expect(claim.eligibility.physics_taught).to eq(true)
  end

  scenario "didn't teach eligible subjects and did not teach eligible subjects at a different eligible school" do
    choose_school eligible_school

    choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
    click_on "Continue"

    click_on "Enter another school"

    choose_school eligible_school

    choose I18n.t("student_loans.questions.eligible_subjects.none_taught")
    click_on "Continue"

    expect(page).to have_text("You did not select an eligible subject")
    expect(page).to have_text("You did not teach an eligible subject at #{eligible_school.name}.")

    click_on "I've tried all of my schools"

    expect(page).to have_text("You're not eligible for this payment")
  end
end
