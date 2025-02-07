require "rails_helper"

RSpec.feature "Admin of eligible FE providers" do
  scenario "manage eligible FE providers" do
    when_further_education_payments_journey_configuration_exists
    sign_in_as_service_operator

    click_link "Manage services"
    click_link "Change Claim a targeted retention incentive payment for further education teachers"

    expect(page).to have_content("Upload history for eligible FE providers")
    expect(page).to have_content("None")

    select AcademicYear.current.to_s, from: "eligible-fe-providers-upload-academic-year-field"
    attach_file "eligible-fe-providers-upload-file-field", eligible_fe_providers_csv_file.path
    click_button "Upload CSV"

    expect(page).to have_select "eligible-fe-providers-upload-academic-year-field", selected: AcademicYear.current.to_s

    expect(page).to have_content("#{last_file_upload_completed_process_at_string}Aaron Admin#{AcademicYear.current}")

    select AcademicYear.current.to_s, from: "eligible-fe-providers-download-academic-year-field"
    click_button "Download CSV"

    downloaded_csv = page.body

    expect(downloaded_csv).to eql(eligible_fe_providers_csv_file.read)
  end

  def eligible_fe_providers_csv_file
    return @eligible_fe_providers_csv_file if @eligible_fe_providers_csv_file

    @eligible_fe_providers_csv_file = Tempfile.new
    @eligible_fe_providers_csv_file.write EligibleFeProvidersImporter.mandatory_headers.join(",") + "\n"

    3.times do
      hash = attributes_for(:eligible_fe_provider)
      @eligible_fe_providers_csv_file.write "#{hash[:ukprn]},#{hash[:max_award_amount].to_f},#{hash[:lower_award_amount].to_f},#{hash[:primary_key_contact_email_address]}\n"
    end

    @eligible_fe_providers_csv_file.rewind

    @eligible_fe_providers_csv_file
  end

  def last_file_upload_completed_process_at_string
    FileUpload
      .latest_version_for(EligibleFeProvider, AcademicYear.current)
      .first
      .completed_processing_at
      .strftime("%-d %B %Y %-l:%M%P")
  end
end
