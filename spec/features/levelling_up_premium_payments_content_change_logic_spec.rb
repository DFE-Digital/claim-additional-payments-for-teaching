require "rails_helper"

RSpec.feature "Claims with different eligibilities content change logic" do
  before do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022))
    start_early_career_payments_claim
    journey_session = Journeys::AdditionalPaymentsForTeaching::Session.last
    journey_session.answers.assign_attributes(qualification: "postgraduate_itt")
    journey_session.save!
    jump_to_claim_journey_page(
      slug: "itt-year",
      journey_session: journey_session
    )
  end

  it "shows the correct subjects for LUP-only and ECP claims" do
    choose "2017 to 2018"
    click_on "Continue"
    expected_subjects = ["Chemistry", "Computing", "Mathematics", "Physics", "None of the above"]
    expect(radio_labels).to eq(expected_subjects)

    click_on "Back"
    choose "2018 to 2019"
    click_on "Continue"
    expected_subjects = ["Chemistry", "Computing", "Mathematics", "Physics", "None of the above"]
    expect(radio_labels).to eq(expected_subjects)
  end

  def radio_labels
    all("label.govuk-radios__label").map(&:text)
  end
end
