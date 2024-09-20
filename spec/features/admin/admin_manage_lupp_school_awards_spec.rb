require "rails_helper"

RSpec.feature "Managing Levelling Up Premium Payments school awards" do
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }

  let(:csv_file) { "spec/fixtures/files/lupp_school_awards_good.csv" }
  let(:csv_file_with_bad_data) { "spec/fixtures/files/lupp_school_awards_bad.csv" }
  let(:csv_file_with_extra_columns) { "spec/fixtures/files/lupp_school_awards_additional_columns.csv" }
  let(:csv_file_without_headers) { "spec/fixtures/files/lupp_school_awards_no_headers.csv" }

  before do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Claim additional payments for teaching")
    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      click_on "Change"
    end
  end

  scenario "downloading school awards" do
    # When no awards exist
    expect(page).not_to have_button "Download CSV"

    # When awards exist
    freeze_time do
      award = create(:levelling_up_premium_payments_award, academic_year: journey_configuration.current_academic_year)
      create(:levelling_up_premium_payments_award, academic_year: journey_configuration.current_academic_year - 1)

      visit current_path
      expect(page).to have_text "The School Targeted Retention Incentive school award amounts for academic year #{journey_configuration.current_academic_year} were updated on #{Time.zone.now.strftime("%-d %B %Y")}"

      within "#download" do
        expect(page).to have_select "Academic year", options: [journey_configuration.current_academic_year, journey_configuration.current_academic_year - 1]
        expect(page).to have_button "Download CSV"

        select journey_configuration.current_academic_year.to_s, from: "download_academic_year"
        click_button "Download CSV"

        expect(page.body).to eq("school_urn,award_amount\n#{award.school_urn},#{award.award_amount}\n")
      end
    end
  end

  scenario "uploading school awards" do
    # When no awards exist
    expect(page).to have_text "No School Targeted Retention Incentive school award data has been uploaded for academic year #{journey_configuration.current_academic_year}."

    # No CSV file
    within "#upload" do
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Choose a CSV file to upload"

    # Good CSV file
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "upload_academic_year"

      attach_file("CSV file", csv_file)
      click_button "Upload CSV"
    end

    expect(page).to have_text "Award amounts for #{journey_configuration.current_academic_year} successfully updated."

    # Different academic year

    within "#upload" do
      select "2024/2025", from: "upload_academic_year"

      attach_file("CSV file", csv_file)
      click_button "Upload CSV"
    end

    expect(page).to have_text "Award amounts for 2024/2025 successfully updated."

    # CSV file with bad data
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "upload_academic_year"

      attach_file("CSV file", csv_file_with_bad_data)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Line 6: School urn is not a number Line 6: Award amount is not a number"

    # CSV file with extra columns
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "upload_academic_year"

      attach_file("CSV file", csv_file_with_extra_columns)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Invalid headers in CSV file. Required headers are school_urn and award_amount"

    # CSV file with no headers
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "upload_academic_year"

      attach_file("CSV file", csv_file_without_headers)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Invalid headers in CSV file. Required headers are school_urn and award_amount"
  end
end
