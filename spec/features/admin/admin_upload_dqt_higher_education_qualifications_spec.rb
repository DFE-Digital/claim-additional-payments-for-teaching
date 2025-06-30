require "rails_helper"

RSpec.feature "Upload DQT higher education " do
  let(:csv_file) { "spec/fixtures/files/dqt_higher_education_qualifications_data.csv" }
  let(:csv_file_without_headers) { "spec/fixtures/files/dqt_higher_education_qualifications_data_no_headers.csv" }

  before do
    sign_in_as_service_admin
    click_on "Claims"
    click_on "Upload DQT HE Qualifications"
    expect(page).to have_content("Choose and upload Higher Education Qualfications data")
  end

  scenario "upload" do
    # No CSV file
    within "#upload" do
      click_button "Upload"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Choose a CSV file with Higher Education Qualifications data to upload"

    # CSV file with no headers
    within "#upload" do
      attach_file("CSV file", csv_file_without_headers)
      click_button "Upload"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "The selected file is missing some expected columns: trn, date_of_birth, nino, subject_code, description"

    # Good CSV file
    expect(DqtHigherEducationQualification.count).to eq 0
    perform_enqueued_jobs do
      within "#upload" do
        attach_file("CSV file", csv_file)
        click_button "Upload"
      end
    end

    expect(page).to have_text "DQT higher education qualifications file uploaded and queued to be imported"
    expect(DqtHigherEducationQualification.count).to eq 4
    expect(page.current_path).to eq("/admin/claims")
  end
end
