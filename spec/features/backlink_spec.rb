require "rails_helper"

RSpec.feature "Backlinking during a claim" do
  scenario "Student Loans journey" do
    visit new_claim_path(StudentLoans.routing_name)
    expect(page).to have_no_link("Back")
    choose_qts_year
    expect(page).to have_link("Back")
    choose_school schools(:penistone_grammar_school)
    click_on "Back"
    expect(page).to have_current_path("/student-loans/claim-school", ignore_query: true)
    click_on "Back"
    expect(page).to have_text(I18n.t("questions.qts_award_year"))
    expect(page).to have_no_link("Back")
  end

  scenario "ECP/LUP journey" do
    lup_school = schools(:hampstead_school)
    expect(LevellingUpPremiumPayments::SchoolEligibility.new(lup_school)).to be_eligible

    visit new_claim_path(EarlyCareerPayments.routing_name)
    expect(page).to have_no_link("Back")
    choose_school lup_school
    expect(page).to have_link("Back")

    # go to deadend
    choose "No"
    click_on "Continue"
    expect(page).to have_link("Back")
    choose "None of the above"
    click_on "Continue"
    expect(page).to have_no_link("Back")
  end

  scenario "ECP/LUP trainee mini journey" do
    lup_school = schools(:hampstead_school)
    expect(LevellingUpPremiumPayments::SchoolEligibility.new(lup_school)).to be_eligible

    visit new_claim_path(EarlyCareerPayments.routing_name)
    choose_school lup_school

    choose "No, I’m a trainee teacher"
    click_on "Continue"
    click_on "Back"

    expect(page).to have_link("Back")
  end
end
