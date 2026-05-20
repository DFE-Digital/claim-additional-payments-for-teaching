require "rails_helper"

RSpec.feature "EYTFI review employment proof preview", feature_flag: [:eytfi_journey] do
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
    allow(TeacherAuth::Config.instance).to receive(:bypass?).and_return(true)
    allow(Dqt::Client).to receive(:new).and_return(mock_client)
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

    expect(page).to have_text("Confirm where you work")
  end

  scenario "uploading an image shows an inline preview on the review page" do
    navigate_to_upload_page

    attach_file "File", Rails.root.join("spec/fixtures/files/employment_proof.png")
    click_button "Upload"

    expect(page).to have_text("Check your document")
    expect(page).to have_css("img[alt='employment_proof.png']")
    expect(page).not_to have_css("a", text: "employment_proof.png")
  end

  scenario "uploading a PDF shows a link instead of an inline preview on the review page" do
    navigate_to_upload_page

    attach_file "File", Rails.root.join("spec/fixtures/files/employment_proof.pdf")
    click_button "Upload"

    expect(page).to have_text("Check your document")
    expect(page).not_to have_css("img")
    expect(page).to have_css("a", text: "employment_proof.pdf")
  end
end
