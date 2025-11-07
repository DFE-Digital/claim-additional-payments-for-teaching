require "rails_helper"

RSpec.feature "Confirming Claimant Contact details" do
  before { create(:journey_configuration, :targeted_retention_incentive_payments) }

  it "redirects to 'email-address' if 'Change email address' is clicked on the One Time Password page" do
    start_targeted_retention_incentive_payments_claim

    journey_session = Journeys::TargetedRetentionIncentivePayments::Session.last
    journey_session.answers.assign_attributes(
      attributes_for(
        :targeted_retention_incentive_payments_answers,
        :submittable,
        email_verified: false
      ).merge(email_address: "david.tau@gmail.com")
    )
    journey_session.save!

    expect(journey_session.reload.answers.email_address).to(
      eq("david.tau@gmail.com")
    )

    expect(journey_session.answers.email_address).not_to(
      eq("david.tau1988@hotmail.co.uk")
    )

    jump_to_claim_journey_page(
      slug: "email-verification",
      journey_session: journey_session
    )

    expect(page).to have_text("Enter the 6-digit passcode")
    expect(page).to have_link(href: claim_path(Journeys::TargetedRetentionIncentivePayments.routing_name, "email-address"))

    click_link("Change email address")

    expect(page).to have_text("Personal details")
    expect(page).to have_text("Email address")

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"

    click_on "Continue"

    expect(journey_session.reload.answers.email_address).not_to(
      eq("david.tau@gmail.com")
    )
    expect(journey_session.answers.email_address).to(
      eql("david.tau1988@hotmail.co.uk")
    )
  end
end
