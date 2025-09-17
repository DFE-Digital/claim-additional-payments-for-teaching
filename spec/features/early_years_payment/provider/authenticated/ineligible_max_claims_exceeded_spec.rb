require "rails_helper"

RSpec.feature "Early years payment provider" do
  scenario "exceeding max claims" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists

    eligible_ey_provider = create(
      :eligible_ey_provider,
      max_claims: 1,
      primary_key_contact_email_address: "seymor.skinner@springfield-elementary.edu",
      nursery_name: "Springfield Elementary Nursery"
    )

    # Existing claim in the current academic year
    create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      academic_year: AcademicYear.current,
      journey_session: create(:early_years_payment_provider_authenticated_session),
      eligibility_attributes: {
        nursery_urn: eligible_ey_provider.urn
      }
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "Start now"
    fill_in "Enter your email address", with: "seymor.skinner@springfield-elementary.edu"
    click_on "Submit"

    mail = ActionMailer::Base.deliveries.last
    magic_link = mail.personalisation[:magic_link]

    visit magic_link

    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    choose "Springfield Elementary Nursery"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/ineligible"
    expect(page).to have_content(
      "You cannot submit any more early years financial incentive payment applications for this nursery. All available expressions of interest have been used."
    )
  end
end
