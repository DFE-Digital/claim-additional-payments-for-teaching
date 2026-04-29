require "rails_helper"

RSpec.feature "Admin of eligible EYTFI providers" do
  let(:eligible_eytfi_providers_csv_file) do
    file_fixture("eligible_eytfi_providers.csv")
  end

  scenario "manage eligible EYTFI providers" do
    when_eytfi_journey_configuration_exists
    sign_in_as_service_operator

    click_link "Manage services"
    click_link "Change Early Years Teachers Financial Incentive Payments"

    select AcademicYear.current.to_s, from: "Academic year"
    attach_file "eligible-eytfi-providers-upload-file-field", eligible_eytfi_providers_csv_file

    expect {
      click_button "Upload CSV"
    }.to change(FileUpload, :count).by(1)

    file_upload = FileUpload.last

    expect(page.current_path).to eql(admin_file_upload_path(file_upload))
  end
end
