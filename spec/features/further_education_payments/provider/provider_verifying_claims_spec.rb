require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    create(:journey_configuration, :further_education_payments_provider)
  end

  xscenario "claim has already been approved"

  xscenario "Problem with the service"

  scenario "Provider skips a head" do
    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_button("Sign in")

    # Attempt to skip signing in
    visit claim_path(journey: "further-education-payments-provider", slug: "verify-claim")

    expect(page).to have_button("Sign in")
  end

  scenario "Provider without access visits email link" do
    # Given I have DSI permission to verify claims for "College A"
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    # And there is a claim for "College A"
    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      "no-access-role-code"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    click_on "Sign in"

    expect(page).to have_text("You do not have access to verify claims for this organisation")
  end

  xscenario "Provider with access to service but for the wrong organisation"

  xscenario "User with no organisation in in FE provider group"

  xscenario "DfE staff visits the approval link"

  scenario "provider approves the claim" do
    # Given I have DSI permission to verify claims for "College A"
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    # And there is a claim for "College A"
    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    # create(
    #   :further_education_payments_eligibility,
    #   current_school: fe_provider,
    #   claim: claim
    # )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    click_on "Sign in"

    # When I complete the approval form
    expect(page).to have_text("Claim reference AB123456")
    expect(page).to have_text("Claimant name Edna Krabappel")
    expect(page).to have_text("Claimant date of birth 3 July 1945")
    expect(page).to have_text("Claimant teacher reference number (TRN) 1234567")
    expect(page).to have_text("Claim date 1 August 2024")

    choose(
      "Yes",
      from: "Does Edna Krabappel have a permanent contract of employment at Springfield A&M?"
    )

    choose(
      "Yes",
      from: "Is Edna Krabappel a member of staff with teaching responsibilities?"
    )

    choose(
      "No",
      from: "Is Edna Krabappel in the first 5 years of their further education teaching career in England?"
    )

    choose(
      "Yes",
      from: "Is Edna Krabappel timetabled to teach an average of 12 hours per week during the current term?"
    )

    choose(
      "Yes",
      from: "For at least half of their timetabled teaching hours, does Edna Krabappel teach 16- to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?"
    )

    choose(
      "Yes",
      from: "For at least half of their timetabled teaching hours, does Edna Krabappel teach: qualifications approved for funding at level 3 and below in the engineering (opens in a new tab) sector subject area?"
    )

    check(
      "To the best of my knowledge, I confirm that the information provided in this form is correct."
    )

    # Then I see a confirmation screen that the claim has been approved
    expect(page).to have_text(
      "Verification complete Claim reference number AB123456"
    )

    # And my FE provider receives an email confirming the claim has been approved
    expect("???").to have_received_email(
      "Verification form AB123456 has been submitted for Edna Krabappel"
    )
  end
end
