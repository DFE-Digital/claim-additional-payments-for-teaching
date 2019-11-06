require "rails_helper"

RSpec.feature "Applicant worked at multiple schools" do
  let(:claim) { Claim.order(:created_at).last }
  let(:eligibility) { claim.eligibility }

  scenario "first claim school is ineligible, but subsequent school is eligible" do
    claim = start_claim
    choose_school schools(:hampstead_school)

    expect(claim.eligibility.reload.claim_school).to eq schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("Hampstead School is not an eligible school.")

    click_on "Enter another school"

    expect(page).to_not have_css("input[value=\"Hampstead School\"]")
    expect(page).to have_text(I18n.t("student_loans.questions.additional_school"))
    expect(page).to_not have_text("If you worked at multiple schools")

    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.claim_school).to eq schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))
  end

  scenario "first claim school is ineligible, as is the subsequent school" do
    start_claim
    choose_school schools(:hampstead_school)

    click_on "Enter another school"

    choose_school schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("Hampstead School is not an eligible school.")

    click_on "I've tried all of my schools"

    expect(page).to have_text("You're not eligible for this payment")
  end
end
