require "rails_helper"

RSpec.feature "Current school with closed claim school" do
  let(:claim_school) { schools(:the_samuel_lister_academy) }

  scenario "Still teaching only has two options" do
    start_claim
    choose_school claim_school
    check "Physics"
    click_on "Continue"

    expect(page).to have_text("Yes")
    expect(page).to have_text("No")
    expect(page).not_to have_text("Yes, at #{claim_school.name}")
    expect(page).not_to have_text("Yes, at another school")
  end

  scenario "Choosing yes to still teaching prompts to search for a school" do
    claim = start_claim
    choose_school claim_school
    check "Physics"
    click_on "Continue"

    choose_still_teaching "Yes"

    expect(claim.eligibility.employment_status).to eq("different_school")
    expect(page).to have_text(I18n.t("questions.current_school"))
    expect(page).to have_button("Search")
  end
end
