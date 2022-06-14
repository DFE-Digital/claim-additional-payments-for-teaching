require "rails_helper"

RSpec.feature "Claims with different eligibilities content change logic" do
  let(:claim) { start_early_career_payments_claim }

  before do
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
  end

  it "shows the correct subjects for LUP-only and ECP claims" do
    visit claim_path(claim.policy.routing_name, "itt-year")
    choose "2017 to 2018"
    click_on "Continue"
    expected_subjects = ["Chemistry", "Computing", "Mathematics", "Physics", "None of the above"]
    expect(radio_labels).to eq(expected_subjects)

    click_on "Back"
    choose "2018 to 2019"
    click_on "Continue"
    expected_subjects = ["Chemistry", "Computing", "Foreign languages", "Mathematics", "Physics", "None of the above"]
    expect(radio_labels).to eq(expected_subjects)
  end

  def radio_labels
    all("label.govuk-radios__label").map(&:text)
  end
end
