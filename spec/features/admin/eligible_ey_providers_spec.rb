require "rails_helper"

RSpec.feature "Admin of eligible ey providers" do
  scenario "manage eligible ey providers" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    sign_in_as_service_operator

    click_link "Manage services"
    click_link "Change Claim an early years financial incentive payment"

    attach_file "eligible-ey-providers-upload-file-field", eligible_ey_providers_csv_file.path
    click_button "Upload CSV"

    click_link "Download CSV"

    downloaded_csv = page.body

    expect(downloaded_csv).to eql(eligible_ey_providers_csv_file.read)
  end

  def eligible_ey_providers_csv_file
    return @eligible_ey_providers_csv_file if @eligible_ey_providers_csv_file

    create(:local_authority, code: "101")

    @eligible_ey_providers_csv_file = Tempfile.new
    @eligible_ey_providers_csv_file.write <<~CSV
      Nursery Name,EYURN / Ofsted URN,LA Code,Nursery Address,Primary Key Contact Email Address,Secondary Contact Email Address (Optional)
      First Nursery,1000001,101,"1 Test Street, Test Town, TE1 1ST",primary@example.com,secondary@example.com
      Second Nursery,1000002,101,"2 Test Street, Test Town, TE1 1ST",primary@example.com,
      Third Nursery,1000003,101,"3 Test Street, Test Town, TE1 1ST",other@example.com,
    CSV
    @eligible_ey_providers_csv_file.rewind

    @eligible_ey_providers_csv_file
  end
end
