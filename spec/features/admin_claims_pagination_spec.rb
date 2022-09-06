require "rails_helper"

RSpec.feature "Admin paginated claims page" do
  before do
    create_list(:claim, 102, :submitted)
    sign_in_as_service_operator
  end

  scenario "Pagination for 102 claims" do
    visit admin_claims_path

    expect(page).to have_content("102 claims awaiting a decision")

    expect(all("div.govuk-pagination__prev").count).to eq(0)
    expect(all("li.govuk-pagination__item").count).to eq(3)
    expect(all("div.govuk-pagination__next").count).to eq(1)

    click_on "Next"

    expect(all("div.govuk-pagination__prev").count).to eq(1)
    expect(all("li.govuk-pagination__item").count).to eq(3)
    expect(all("div.govuk-pagination__next").count).to eq(1)

    click_on "Next"

    expect(all("div.govuk-pagination__prev").count).to eq(1)
    expect(all("li.govuk-pagination__item").count).to eq(3)
    expect(all("div.govuk-pagination__next").count).to eq(0)
  end
end
