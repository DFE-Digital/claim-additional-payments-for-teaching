require "rails_helper"

RSpec.feature "Managing targeted_retention_incentive Payments school awards" do
  let!(:journey_configuration) do
    FeatureFlag.enable!(:tri_only_journey)
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
  end

  let(:csv_file) { "spec/fixtures/files/targeted_retention_incentive_school_awards_good.csv" }
  let(:csv_file_with_bad_data) { "spec/fixtures/files/targeted_retention_incentive_school_awards_bad.csv" }
  let(:csv_file_with_extra_columns) { "spec/fixtures/files/targeted_retention_incentive_school_awards_additional_columns.csv" }
  let(:csv_file_without_headers) { "spec/fixtures/files/targeted_retention_incentive_school_awards_no_headers.csv" }

  before do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Claim a targeted retention incentive payment")
    within(find("tr[data-policy-configuration-routing-name=\"#{journey_configuration.routing_name}\"]")) do
      click_on "Change"
    end
  end

  scenario "downloading school awards" do
    # When no awards exist
    expect(page).not_to have_button "Download CSV"

    # When awards exist
    freeze_time do
      award = create(:targeted_retention_incentive_payments_award, academic_year: journey_configuration.current_academic_year)
      create(:targeted_retention_incentive_payments_award, academic_year: journey_configuration.current_academic_year - 1)

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

    expect(page).to have_content("Upload History For School Targeted Retention Incentives School Awards")
    expect(page).to have_content("None")

    # No CSV file
    within "#upload" do
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Choose a CSV file to upload"

    # Good CSV file
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "targeted_retention_incentive_payments_awards_upload[academic_year]"

      attach_file("CSV file", csv_file)
      click_button "Upload CSV"
    end

    expect(page).to have_text "Award amounts for #{journey_configuration.current_academic_year} successfully updated."

    expect(page).to have_content(
      "#{last_file_upload_completed_process_at_string}Aaron Admin#{journey_configuration.current_academic_year}"
    )

    # Different academic year

    within "#upload" do
      select (journey_configuration.current_academic_year + 1).to_s, from: "targeted_retention_incentive_payments_awards_upload[academic_year]"

      attach_file("CSV file", csv_file)
      click_button "Upload CSV"
    end

    expect(page).to have_text "Award amounts for #{journey_configuration.current_academic_year + 1} successfully updated."

    # CSV file with bad data
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "targeted_retention_incentive_payments_awards_upload[academic_year]"

      attach_file("CSV file", csv_file_with_bad_data)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Line 6: School urn is not a number"

    # CSV file with extra columns
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "targeted_retention_incentive_payments_awards_upload[academic_year]"

      attach_file("CSV file", csv_file_with_extra_columns)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Invalid headers in CSV file. Required headers are school_urn and award_amount"

    # CSV file with no headers
    within "#upload" do
      select journey_configuration.current_academic_year.to_s, from: "targeted_retention_incentive_payments_awards_upload[academic_year]"

      attach_file("CSV file", csv_file_without_headers)
      click_button "Upload CSV"
    end

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Invalid headers in CSV file. Required headers are school_urn and award_amount"
  end

  def last_file_upload_completed_process_at_string
    FileUpload
      .latest_version_for(Policies::TargetedRetentionIncentivePayments::Award, journey_configuration.current_academic_year)
      .first
      .completed_processing_at
      .strftime("%-d %B %Y %-l:%M%P")
  end
end
