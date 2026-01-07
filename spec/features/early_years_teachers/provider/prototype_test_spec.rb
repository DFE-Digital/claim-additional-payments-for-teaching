require "rails_helper"

# This test is for ensuring the prototype journey is wired up correctly.
# It should be removed once we start beta.
RSpec.describe "Prototype Test" do
  it "can navigate the prototype journey" do
    create(:journey_configuration, :early_years_teachers_provider)

    visit landing_page_path(Journeys::EarlyYearsTeachers::Provider.routing_name)

    click_link "Start now"

    fill_in "What is your favourite colour?", with: "Blue"
    click_on "Continue"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("Blue")
  end
end
