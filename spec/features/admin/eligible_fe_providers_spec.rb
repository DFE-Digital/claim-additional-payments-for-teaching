require "rails_helper"

RSpec.feature "Admin of eligible FE providers" do
  scenario "manage eligible FE providers" do
    when_further_education_payments_journey_configuration_exists
    sign_in_as_service_operator

    click_link "Manage services"
    click_link "Change Claim incentive payments for further education teachers"

    attach_file "eligible-fe-providers-file-field", eligible_fe_providers_csv_file.path
    click_button "Upload CSV"

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
      @eligible_fe_providers_csv_file.write "#{hash[:ukprn]},#{hash[:max_award_amount].to_f},#{hash[:lower_award_amount].to_f}\n"
    end

    @eligible_fe_providers_csv_file.rewind

    @eligible_fe_providers_csv_file
  end
end
