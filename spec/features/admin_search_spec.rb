require "rails_helper"

RSpec.feature "Admin search" do
  before { sign_in_as_service_operator }

  let!(:claim1) { create(:claim, :submitted, surname: "Wayne") }
  let!(:claim2) { create(:claim, :submitted, surname: "Wayne") }
  let!(:lup_claim) { create(:claim, :submitted, surname: "Smith", policy: LevellingUpPremiumPayments) }

  scenario "redirects a service operator to the claim if there is only one match" do
    visit search_admin_claims_path

    fill_in :reference, with: claim1.reference
    click_button "Search"

    expect(page).to have_content(claim1.reference)
    expect(page).to have_content(claim1.teacher_reference_number)
  end

  scenario "it lists claims if there is more than one match" do
    visit search_admin_claims_path

    fill_in :reference, with: "wayne"
    click_button "Search"

    expect(page).to have_content(claim1.reference)
    expect(page).to have_content(claim2.reference)

    find("a[href='#{admin_claim_tasks_path(claim1)}']").click

    expect(page).to have_content(claim1.teacher_reference_number)
  end

  scenario "render LUP claim view page" do
    visit search_admin_claims_path

    fill_in :reference, with: lup_claim.surname
    click_button "Search"

    expect(page).to have_content(lup_claim.reference)
    expect(page).to have_content("Levelling Up Premium Payments")
  end
end
