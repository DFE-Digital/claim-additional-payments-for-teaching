require "rails_helper"

RSpec.describe "DfE Analytics on validation error" do
  it "sends validation errors to dfe analytics" do
    create(:journey_configuration, :further_education_payments)

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)

    click_link "Start now"

    expect(page).to have_content("Do you have a GOV.UK One Login account?")

    # Don't choose an option to trigger validation error, expect the validation
    # error to be sent to dfe analytics

    expect(DfE::Analytics::SendEvents).to receive(:do) do |events|
      expect(events.first.as_json["data"]).to eq([
        {
          "key" => "slug",
          "value" => ["have-one-login-account"]
        },
        {
          "key" => "errors",
          "value" => [
            {
              have_one_login_account: [
                "Select yes if you have a GOV.UK One Login account"
              ]
            }.to_json
          ]
        }
      ])
    end

    click_button "Continue"

    # Choose an option, expect the validation error not to be sent to dfe
    # analytics

    choose "Yes"

    expect(DfE::Analytics::SendEvents).not_to receive(:do)

    click_button "Continue"
  end
end
