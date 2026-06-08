require "rails_helper"

RSpec.feature "Postcode journey desired behavior", feature_flag: [:eytfi_journey] do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: true
    )
  end

  let(:mock_teacher_resource) do
    instance_double(
      "Dqt::TeacherResource",
      find: mock_teacher
    )
  end

  let(:mock_client) do
    instance_double(
      "Dqt::Client",
      teacher: mock_teacher_resource
    )
  end

  before do
    create(:journey_configuration, :early_years_teachers_financial_incentive_payments)

    create(:eligible_eytfi_provider, name: "Springfield nursery")

    OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new({
      provider: "teacher",
      extra: {
        raw_info: {
          sub: "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}",
          trn: "1234567",
          email: "john.doe@example.com",
          verified_name: ["John", "Doe"],
          verified_date_of_birth: "1970-12-13"
        }
      }
    })

    allow(Dqt::Client).to receive(:new).and_return(mock_client)
  end

  scenario "postcode lookup with no matches keeps claimant on postcode page and allows manual entry" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(nil)

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    expect(page).to have_text("What is your home address?")
    expect(page).to have_text("Address not found")
    expect(page).to have_field("Postcode", with: "SO16 9FX")
    expect(page).to have_button("Enter your address manually")

    click_button "Enter your address manually"

    expect(page).to have_text("What is your address?")
  end

  scenario "claimant can navigate from select address page to manual address page" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(
        [
          {
            address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 1, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          },
          {
            address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 10, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          }
        ]
      )

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    expect(page).to have_text("Select an address")
    click_on "I can’t find my address in the list"

    expect(page).to have_text("What is your address?")
  end

  scenario "postcode search unavailable still allows manual address entry" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_raise(OrdnanceSurvey::Client::ResponseError, "Service unavailable")

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    expect(page).to have_text("What is your home address?")
    expect(page).to have_text("Postcode search is currently unavailable")
    expect(page).to have_button("Enter your address manually")

    click_button "Enter your address manually"

    expect(page).to have_text("What is your address?")
  end

  scenario "manually entering address from postcode journey proceeds to gender page" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(nil)

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    click_button "Enter your address manually"

    expect(page).to have_text("What is your address?")
    fill_in "House number or name", with: "1"
    fill_in "Building and street", with: "Grey Street"
    fill_in "Town or city", with: "Newcastle upon Tyne"
    fill_in "County", with: "Tyne and Wear"
    fill_in "Postcode", with: "NE1 6EE"
    click_button "Continue"

    expect(page).to have_text("Are you recorded as male or female on your employer’s payroll system?")
  end

  scenario "selecting an address from postcode journey proceeds to gender page" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(
        [
          {
            address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 1, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          },
          {
            address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 10, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          }
        ]
      )

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    expect(page).to have_text("Select an address")
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_button "Continue"

    expect(page).to have_text("Are you recorded as male or female on your employer’s payroll system?")
  end

  scenario "from gender page claimant can go back, change address, and continue again" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(
        [
          {
            address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 1, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          },
          {
            address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 10, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          }
        ]
      )

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    expect(page).to have_text("Select an address")
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_button "Continue"

    expect(page).to have_text("Are you recorded as male or female on your employer’s payroll system?")

    click_link "Back"

    expect(page).to have_text("Select an address")
    choose "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_button "Continue"

    expect(page).to have_text("Are you recorded as male or female on your employer’s payroll system?")
  end

  scenario "from gender page claimant can go back and switch to manual address entry" do
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(
        [
          {
            address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 1, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          },
          {
            address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
            address_line_1: "FLAT 10, MILLBROOK TOWER",
            address_line_2: "WINDERMERE AVENUE",
            address_line_3: "SOUTHAMPTON",
            postcode: "SO16 9FX"
          }
        ]
      )

    navigate_to_eytfi_postcode_page

    fill_in "Postcode", with: "SO16 9FX"
    click_button "Search"

    expect(page).to have_text("Select an address")
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_button "Continue"

    expect(page).to have_text("Are you recorded as male or female on your employer’s payroll system?")
    click_link "Back"

    expect(page).to have_text("Select an address")
    click_on "I can’t find my address in the list"

    expect(page).to have_text("What is your address?")
  end

  def navigate_to_eytfi_postcode_page
    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text("Which nursery do you teach in?")
    fill_in "claim[nursery_search_query]", with: "Springfield nursery"
    click_button "Continue"

    choose "Springfield nursery"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    check "I spend at least half"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    click_button "Continue"

    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text("You may be eligible for a recognition payment")
    choose "Yes"
    click_button "Continue"

    upload_employment_proof

    expect(page).to have_text("How we’ll use your information")
    click_button "Continue"

    expect(page).to have_text("What is your home address?")
  end
end
