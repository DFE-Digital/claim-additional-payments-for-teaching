require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    FeatureFlag.create!(
      name: "fe_provider_identity_verification",
      enabled: true
    )

    create(
      :journey_configuration,
      :further_education_payments_provider,
      current_academic_year: AcademicYear.new(2024)
    )
    # Stub fetching name from DSI, not required for these tests
    stub_request(
      :get,
      %r{https://example.com/organisations/.*}
    ).to_return(
      status: 404,
      body: nil
    )
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
      status: 404,
      user_type: "provider"
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
      "some-role",
      user_type: "provider"
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
      "some-other-role",
      user_type: "provider"
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
      ],
      user_type: "provider"
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

  scenario "provider visits a claim with an in progress session" do
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
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
      ],
      teacher_reference_number: "1234567"
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"

    expect(page).to have_summary_item(
      key: "Claim reference",
      value: "AB123456"
    )

    expect(page).to have_summary_item(
      key: "Claimant name",
      value: "Edna Krabappel"
    )

    expect(page).to have_summary_item(
      key: "Claimant date of birth",
      value: "3 July 1945"
    )

    expect(page).to have_summary_item(
      key: "Claimant teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "Claim date",
      value: "1 August 2024"
    )

    within_fieldset(
      "Does Edna have a fixed-term contract of employment covering " \
      "the full academic year at Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna timetabled to teach an average of more than 12 hours per " \
      "week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna teach 16- to 19-year-olds, including those up to " \
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
      "Edna teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to " \
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
      ],
      teacher_reference_number: "1234567"
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"

    expect(page).to have_summary_item(
      key: "Claim reference",
      value: "AB123456"
    )

    expect(page).to have_summary_item(
      key: "Claimant name",
      value: "Edna Krabappel"
    )

    expect(page).to have_summary_item(
      key: "Claimant date of birth",
      value: "3 July 1945"
    )

    expect(page).to have_summary_item(
      key: "Claimant teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "Claim date",
      value: "1 August 2024"
    )

    within_fieldset(
      "Does Edna have a fixed-term contract of employment at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Has Edna worked at Springfield A and M for the whole of the spring term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna timetabled to teach an average of between 2.5 and 12 hours " \
      "per week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna teach 16- to 19-year-olds, including those up to " \
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
      "Edna teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Will Edna be timetabled to teach at least 2.5 hours per " \
      "week next term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to " \
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
      ],
      teacher_reference_number: "1234567"
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"

    expect(page).to have_summary_item(
      key: "Claim reference",
      value: "AB123456"
    )

    expect(page).to have_summary_item(
      key: "Claimant name",
      value: "Edna Krabappel"
    )

    expect(page).to have_summary_item(
      key: "Claimant date of birth",
      value: "3 July 1945"
    )

    expect(page).to have_summary_item(
      key: "Claimant teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "Claim date",
      value: "1 August 2024"
    )

    within_fieldset(
      "Does Edna have a variable hours contract of employment at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Has Edna worked at Springfield A and M for the whole of the spring term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna timetabled to teach an average of between 2.5 and 12 hours " \
      "per week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna teach 16- to 19-year-olds, including those up to " \
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
      "Edna teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Will Edna be timetabled to teach at least 2.5 hours per " \
      "week next term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to " \
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

  scenario "provider attempts to verify a rejected claim" do
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

    create(:decision, :rejected, claim: claim)

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    expect(page).to have_content(
      "This verification request is no longer active."
    )

    expect(page).to have_content("claim reference #{claim.reference}")
  end

  scenario "provider verifies a claim that requires id verification" do
    fe_provider = create(:school, :further_education, name: "Springfield A and M")

    create(
      :eligible_fe_provider,
      primary_key_contact_email_address: "g.chalmers@springfield-unified-school-district.edu",
      ukprn: fe_provider.ukprn
    )

    eligibility = create(
      :further_education_payments_eligibility,
      school: fe_provider,
      teaching_hours_per_week: "between_2_5_and_12",
      contract_type: "fixed_term",
      fixed_term_full_year: false,
      subjects_taught: ["engineering_manufacturing"],
      engineering_manufacturing_courses: [
        "approved_level_321_transportation",
        "level2_3_apprenticeship"
      ],
      teacher_reference_number: "1234567"
    )

    claim = create(
      :claim,
      :further_education,
      eligibility:,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
      onelogin_idv_at: DateTime.new(2024, 8, 1, 9, 0, 0),
      identity_confirmed_with_onelogin: false
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    allow(ClaimVerifierJob).to receive(:perform_later)

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a targeted retention incentive payment claim"

    expect(page).to have_summary_item(
      key: "Claim reference",
      value: "AB123456"
    )

    expect(page).to have_summary_item(
      key: "Claimant name",
      value: "Edna Krabappel"
    )

    expect(page).not_to have_text("Claimant date of birth")

    expect(page).not_to have_text("3 July 1945")

    expect(page).to have_summary_item(
      key: "Claimant teacher reference number (TRN)",
      value: "1234567"
    )

    expect(page).to have_summary_item(
      key: "Claim date",
      value: "1 August 2024"
    )

    within_fieldset(
      "Does Edna have a fixed-term contract of employment at " \
      "Springfield A and M?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna a member of staff with teaching responsibilities?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna in the first 5 years of their further education " \
      "teaching career in England?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Has Edna worked at Springfield A and M for the whole of the spring term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Is Edna timetabled to teach an average of between 2.5 and 12 hours " \
      "per week during the current term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "For at least half of their timetabled teaching hours, does " \
      "Edna teach 16- to 19-year-olds, including those up to " \
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
      "Edna teach:"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Will Edna be timetabled to teach at least 2.5 hours per " \
      "week next term?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to any " \
      "performance measures as a result of continuous poor teaching standards?"
    ) do
      choose "Yes"
    end

    within_fieldset(
      "Can you confirm that Edna is not currently subject to " \
      "disciplinary action?"
    ) do
      choose "Yes"
    end

    perform_enqueued_jobs do
      click_on "Continue"
    end

    expect("g.chalmers@springfield-unified-school-district.edu").not_to(
      have_received_email(
        ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_PROVIDER_VERIFICATION_CONFIRMATION_EMAIL_TEMPLATE_ID]
      )
    )

    expect(page.current_path).to end_with "verify-identity"

    expect(page).to have_content(
      "We need you to verify the claimant’s identity"
    )

    fill_in "Day", with: "3"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1945"

    fill_in(
      "What is the postcode of Edna’s current home address?",
      with: "TE57 1NG"
    )

    fill_in(
      "What is Edna’s National Insurance number?",
      with: "QQ123456C"
    )

    choose "Yes" # has valid passport

    fill_in("Passport number", with: "123456789")

    check(
      "To the best of my knowledge, I confirm that I have verified the " \
      "claimant’s identity and the information provided in this form is " \
      "correct."
    )

    perform_enqueued_jobs do
      click_on "Submit"
    end

    expect("g.chalmers@springfield-unified-school-district.edu").to(
      have_received_email(
        ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_PROVIDER_VERIFICATION_CONFIRMATION_EMAIL_TEMPLATE_ID]
      )
    )

    expect(page).to have_content "Verification complete"
    expect(page).to have_text "Claim reference number AB123456"
  end
end
