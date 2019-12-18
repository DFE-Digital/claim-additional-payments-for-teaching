require "rails_helper"

RSpec.feature "Bypassing GOV.UK Verify" do
  scenario "Teacher can submit a claim without going through GOV.UK Verify" do
    @claim = start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching
    choose_leadership
    click_on "Continue"

    expect(page).to have_text("How we will use the information you provide")

    # At this point the teacher would normally go off to GOV.UK Verify for
    # identity verification. To simulate a user that has failed GOV.UK Verify,
    # we visit the URL where such users would be directed to after their GOV.UK
    # Verify attempt.

    visit claim_path(StudentLoans.routing_name, "name")

    expect(page).to have_text(I18n.t("questions.name"))
    fill_in "First name", with: "Dougie"
    fill_in "Middle names", with: "Cooper"
    fill_in "Last name", with: "Jones"
    click_on "Continue"

    @claim.reload
    expect(@claim.first_name).to eql("Dougie")
    expect(@claim.middle_name).to eql("Cooper")
    expect(@claim.surname).to eql("Jones")
  end
end
