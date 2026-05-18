# frozen_string_literal: true

require "rails_helper"

RSpec.feature "EYTFI employment proof upload validation", feature_flag: [:eytfi_journey] do
  let(:mock_teacher) do
    instance_double("Dqt::Teacher", has_eligible_eytfi_qualification?: true)
  end

  let(:mock_teacher_resource) do
    instance_double("Dqt::TeacherResource", find: mock_teacher)
  end

  let(:mock_client) do
    instance_double("Dqt::Client", teacher: mock_teacher_resource)
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

    navigate_to_upload_page
  end

  scenario "shows an error when the file type is not allowed" do
    Tempfile.create(["employment_proof", ".txt"]) do |file|
      file.write("test content")
      file.flush

      attach_file "File", file.path
      click_on "Upload"
    end

    expect(page).to have_text("The selected file must be a PDF, JPG, PNG or HEIC")
  end

  scenario "shows an error when the file is too large" do
    stub_const(
      "Journeys::EarlyYearsTeachersFinancialIncentivePayments::UploadEmploymentProofForm::MAX_FILE_SIZE",
      1.kilobyte
    )

    Tempfile.create(["employment_proof", ".pdf"]) do |file|
      file.write("x" * 2.kilobytes)
      file.flush

      attach_file "File", file.path
      click_on "Upload"
    end

    expect(page).to have_text("The selected file must be smaller than 20MB")
  end

  def navigate_to_upload_page
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    choose "Springfield nursery"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    click_button "Continue"

    perform_enqueued_jobs { click_button "Continue" }

    choose "Yes"
    click_button "Continue"
  end
end
