require "rails_helper"

RSpec.describe "EYTFIP with teacher auth bypass", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    allow(TeacherAuth::Config.instance).to receive(:bypass?).and_return(true)
  end

  scenario "it auto generates dummy data to by pass teacher auth" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    expect(page).to have_text "Claim an early years teacher recognition payment"
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    click_button "Continue"

    expect(page).to have_text "You are eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Bypass Teacher Auth"
    expect(find_field("Full name").value).to be_present
    expect(find_field("Day").value).to be_present
    expect(find_field("Month").value).to be_present
    expect(find_field("Year").value).to be_present
    expect(find_field("Email").value).to be_present
    expect(find_field("TRN").value).to be_present
    expect(find_field("One Login UID").value).to be_present
    click_button "Continue"
  end
end
