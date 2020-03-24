require "rails_helper"

RSpec.feature "Admin search" do
  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  let!(:claim1) { create(:claim, :submitted, surname: "Wayne") }
  let!(:claim2) { create(:claim, :submitted, surname: "Wayne") }

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
end
