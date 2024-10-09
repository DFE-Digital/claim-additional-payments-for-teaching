require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    create(:journey_configuration, :further_education_payments_provider)
  end

  scenario "provider visits a claim without service access" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
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

    # https://github.com/DFE-Digital/login.dfe.public-api?tab=readme-ov-file#get-user-access-to-service
    stub_failed_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      status: 404
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text("You do not have access to this service")

    expect(page).to have_text(
      "You can request access to verify retention payments for further education teachers using DfE Sign-in."
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text("You do not have access to this service")

    expect(page).to have_text(
      "You can request access to verify retention payments for further education teachers using DfE Sign-in."
    )
  end

  scenario "provider visits a claim for the wrong organisation" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    other_provider = create(
      :school,
      :further_education,
      name: "Springfield Elementary"
    )

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: other_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      "some-role"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text(
      "The organisation you have used to log in to DfE Sign-in does not match the organisation in the claim."
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text(
      "The organisation you have used to log in to DfE Sign-in does not match the organisation in the claim."
    )

    expect(page).to have_link("Sign out", href: Journeys::FurtherEducationPayments::Provider.sign_out_url)
  end

  scenario "provider visits claim with the wrong role" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
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
      "some-other-role"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )

    expect(page).to have_text(
      "contact an approver at your organisation to confirm your access rights"
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )
  end

  scenario "admin visits the claim" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
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
      [
        DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE
      ]
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )

    expect(page).to have_text(
      "DfE staff do not have access to verify retention payments for further education teachers."
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )
  end

  scenario "provider visits a claim with an inprogress session" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    claim_1 = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "CLAIM1",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim_1,
      school: fe_provider,
      teaching_hours_per_week: "more_than_12",
      contract_type: "fixed_term"
    )

    claim_2 = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "CLAIM2",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim_2,
      school: fe_provider,
      teaching_hours_per_week: "more_than_12",
      contract_type: "fixed_term"
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_1_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim_1)

    claim_2_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim_2)

    visit claim_1_link

    click_on "Start now"

    visit claim_2_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"

    expect(page).to have_text "Claim referenceCLAIM2"
  end

  scenario "provider visits a claim that has already been verified" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      :verified,
      claim: claim,
      school: fe_provider
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "This claim has already been verified"

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text "This claim has already been verified"
  end

  scenario "provider approves a long term fixed contract claim" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider,
      teaching_hours_per_week: "more_than_12",
      contract_type: "fixed_term",
      fixed_term_full_year: true,
      subjects_taught: ["engineering_manufacturing"],
      engineering_manufacturing_courses: [
        "approved_level_321_transportation",
        "level2_3_apprenticeship"
      ]
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"
    # The text generated by the dl tag doesn not include a space between the
    # label and value (displays as expected in browser).
    expect(page).to have_text "Claim referenceAB123456"
    expect(page).to have_text "Claimant nameEdna Krabappel"
    expect(page).to have_text "Claimant date of birth3 July 1945"
    # FIXME RL enable this test once we've added the TRN to the eligibility
    # expect(page).to have_text "Claimant teacher reference number (TRN)1234567"
    expect(page).to have_text "Claim date1 August 2024"

    within_fieldset(
      "Does Edna Krabappel have a fixed-term contract of employment covering " \
      "the full academic year at Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel timetabled to teach an average of 12 hours or more " \
      "per week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
      "age 25 with an Education, Health and Care Plan (EHCP)?"
    ) do
      choose "Yes"
    end

    expect(page).to have_text(
      "Qualifications approved for funding at level 3 and below in the " \
      "transportation operations and maintenance (opens in new tab) sector " \
      "subject area"
    )

    expect(page).to have_text(
      "Level 2 or level 3 apprenticeships in the engineering and " \
      "manufacturing occupational route (opens in new tab)"
    )

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to " \
      "disciplinary action?"
    ) do
      choose "Yes"
    end

    check "To the best of my knowledge, I confirm that the information provided in this form is correct."

    click_on "Submit"

    expect(page).to have_content "Verification complete"
    expect(page).to have_text "Claim reference number AB123456"
  end

  scenario "provider approves a short term fixed contract claim" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider,
      teaching_hours_per_week: "between_2_5_and_12",
      contract_type: "fixed_term",
      fixed_term_full_year: false,
      subjects_taught: ["engineering_manufacturing"],
      engineering_manufacturing_courses: [
        "approved_level_321_transportation",
        "level2_3_apprenticeship"
      ]
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"
    # The text generated by the dl tag doesn not include a space between the
    # label and value (displays as expected in browser).
    expect(page).to have_text "Claim referenceAB123456"
    expect(page).to have_text "Claimant nameEdna Krabappel"
    expect(page).to have_text "Claimant date of birth3 July 1945"
    # FIXME RL enable this test once we've added the TRN to the eligibility
    # expect(page).to have_text "Claimant teacher reference number (TRN)1234567"
    expect(page).to have_text "Claim date1 August 2024"

    within_fieldset(
      "Does Edna Krabappel have a fixed-term contract of employment at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Has Edna Krabappel taught for at least one academic term at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel timetabled to teach an average of 2.5 hours or " \
      "more but less than 12 hours per week"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
      "age 25 with an Education, Health and Care Plan (EHCP)?"
    ) do
      choose "Yes"
    end

    expect(page).to have_text(
      "Qualifications approved for funding at level 3 and below in the " \
      "transportation operations and maintenance (opens in new tab) sector " \
      "subject area"
    )

    expect(page).to have_text(
      "Level 2 or level 3 apprenticeships in the engineering and " \
      "manufacturing occupational route (opens in new tab)"
    )

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Will Edna Krabappel be timetabled to teach at least 2.5 hours per " \
      "week next term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to " \
      "disciplinary action?"
    ) do
      choose "Yes"
    end

    check(
      "To the best of my knowledge, I confirm that the information " \
      "provided in this form is correct."
    )

    click_on "Submit"

    expect(page).to have_content "Verification complete"
    expect(page).to have_text "Claim reference number AB123456"
  end

  scenario "provider approves a variable contract claim" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider,
      contract_type: "variable_hours",
      teaching_hours_per_week: "between_2_5_and_12",
      subjects_taught: ["engineering_manufacturing"],
      engineering_manufacturing_courses: [
        "approved_level_321_transportation",
        "level2_3_apprenticeship"
      ]
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"
    # The text generated by the dl tag doesn not include a space between the
    # label and value (displays as expected in browser).
    expect(page).to have_text "Claim referenceAB123456"
    expect(page).to have_text "Claimant nameEdna Krabappel"
    expect(page).to have_text "Claimant date of birth3 July 1945"
    # FIXME RL enable this test once we've added the TRN to the eligibility
    # expect(page).to have_text "Claimant teacher reference number (TRN)1234567"
    expect(page).to have_text "Claim date1 August 2024"

    within_fieldset(
      "Does Edna Krabappel have a variable hours contract of employment at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Has Edna Krabappel taught for at least one academic term at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna Krabappel timetabled to teach an average of 2.5 hours or " \
      "more but less than 12 hours per week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
      "age 25 with an Education, Health and Care Plan (EHCP)?"
    ) do
      choose "Yes"
    end

    expect(page).to have_text(
      "Qualifications approved for funding at level 3 and below in the " \
      "transportation operations and maintenance (opens in new tab) sector " \
      "subject area"
    )

    expect(page).to have_text(
      "Level 2 or level 3 apprenticeships in the engineering and " \
      "manufacturing occupational route (opens in new tab)"
    )

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna Krabappel teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Will Edna Krabappel be timetabled to teach at least 2.5 hours per " \
      "week next term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna Krabappel is not currently subject to " \
      "disciplinary action?"
    ) do
      choose "Yes"
    end

    check(
      "To the best of my knowledge, I confirm that the information " \
      "provided in this form is correct."
    )

    click_on "Submit"

    expect(page).to have_content "Verification complete"
    expect(page).to have_text "Claim reference number AB123456"
  end

  scenario "provider visits the landing page" do
    visit(
      Journeys::FurtherEducationPayments::Provider::SlugSequence.start_page_url
    )

    expect(page).to have_text "You cannot access this service from DfE Sign-in"
  end
end
