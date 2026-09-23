require "rails_helper"

# this is an alternative happy path
# after coming back from Teacher Auth
# we call TRS with TRN
# this payload is missing NI number
# so user must enter missing NI number

RSpec.describe "new STRI journey", feature_flag: [:new_stri] do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)

    OmniAuth.config.mock_auth[:teacher_school] = OmniAuth::AuthHash.new({
      provider: "teacher_school",
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

    stub_request(
      :get,
      "https://dqt-api.education.gov.uk/v3/persons/1234567?include=alerts,induction,routesToProfessionalStatuses"
    ).to_return(
      status: 200,
      body: {
        "trn" => "1234567",
        "firstName" => "John",
        "middleName" => "",
        "dateOfBirth" => "1970-12-13",
        "nationalInsuranceNumber" => "",
        "emailAddress" => "john.doe@example.com",
        "qts" => nil,
        "eyts" => {
          "holdsFrom" => "2015-10-22",
          "routes" => [
            {
              "routeToProfessionalStatusType" => {
                "routeToProfessionalStatusTypeId" => "11111",
                "name" => "EYTS ITT Migrated",
                "professionalStatusType" => "EarlyYearsTeacherStatus"
              }
            }
          ]
        },
        "routesToProfessionalStatuses" => [
          {
            "routeToProfessionalStatusId" => "222222",
            "routeToProfessionalStatusType" => {
              "routeToProfessionalStatusTypeId" => "33333",
              "name" => "EYTS ITT Migrated",
              "professionalStatusType" => "EarlyYearsTeacherStatus"
            },
            "status" => "Holds",
            "holdsFrom" => "2015-10-22",
            "trainingStartDate" => "2014-09-30",
            "trainingEndDate" => nil,
            "trainingSubjects" => [],
            "trainingAgeSpecialism" => {
              "type" => "Range"
            },
            "trainingCountry" => {
              "reference" => "GB",
              "name" => "United Kingdom"
            },
            "trainingProvider" => {
              "ukprn" => "10000000",
              "name" => "SpringField University"
            },
            "degreeType" => nil,
            "inductionExemption" => {
              "isExempt" => false,
              "exemptionReasons" => []
            }
          }
        ],
        "qtlsStatus" => "None"
      }.to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  let(:school) do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )
  end

  scenario "partial happy path with missing NI data" do
    visit landing_page_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name)
    expect(page).to have_text "Use this service to find out if you can get an early career teacher payment."
    click_link "Start now"

    expect(page).to have_text "Enter the school name or postcode using at least 3 characters"
    fill_in "What school do you teach at?", with: school.name
    click_button "Continue"

    expect(page).to have_text "Select your school from the search results."
    choose school.name
    click_button "Continue"

    expect(page).to have_text "Do you spend at least half of your contracted"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "You will need to sign in to your GOV.UK One Login account to apply"
    click_button "Continue"

    expect(page).to have_text "Querying teacher details"
    perform_enqueued_jobs
    click_button "Continue"

    expect(page).to have_text "Enter your National Insurance number"
    fill_in "Enter your National Insurance number", with: "AB123456C"
    click_button "Continue"

    expect(page).to have_text "Teacher details"
  end
end
