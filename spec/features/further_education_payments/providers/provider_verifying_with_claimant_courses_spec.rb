require "rails_helper"

RSpec.feature "Provider verifying claims", feature_flag: :provider_dashboard do
  scenario "with custom subjects and courses - Yes to teaching listed courses" do
    fe_provider = create(
      :school,
      :further_education,
      name: "Springfield College"
    )

    sign_in_to(fe_provider)

    claim = create(
      :claim,
      :submitted,
      :further_education,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
      eligibility_attributes: {
        school: fe_provider,
        teacher_reference_number: "1234567",
        subjects_taught: ["maths", "physics"],
        maths_courses: ["approved_level_321_maths", "gcse_maths"],
        physics_courses: ["gcse_physics"]
      }
    )

    visit(
      edit_further_education_payments_providers_claim_verification_path(claim)
    )

    # Check claim reference appears in the caption
    expect(page).to have_content("Review claim - AB123456")
    # Check claimant name appears in the heading
    expect(page).to have_selector("h1", text: "Edna Krabappel")

    # Open the collapsible details section and check its content
    find("summary", text: "Claim details").click
    within("details[open]") do
      expect(page).to have_content("TRN")
      expect(page).to have_content("1234567")
      expect(page).to have_content("Date submitted")
      expect(page).to have_content("1 October 2025")
    end

    within_fieldset(
      "Is Edna Krabappel a member of staff with teaching responsibilities?"
    ) { choose "Yes" }

    click_on "Continue"

    within_fieldset(
      "Is Edna Krabappel in the first 5 years of their further education " \
      "(FE) teaching career in England?"
    ) { choose "Yes" }

    click_on "Continue"

    within_fieldset("Does Edna Krabappel have a teaching qualification?") do
      choose "Yes"
    end

    click_on "Continue"

    within_fieldset(
      "What type of contract does Edna Krabappel have with " \
      "Springfield College?"
    ) { choose "Permanent" }

    click_on "Continue"

    # Performance and discipline
    within_fieldset(
      "Is Edna Krabappel currently subject to any performance measures?"
    ) { choose "No" }

    within_fieldset(
      "Is Edna Krabappel currently subject to any disciplinary action?"
    ) { choose "No" }

    click_on "Continue"

    # Contracted hours
    within_fieldset(
      "On average, how many hours per week was Edna Krabappel timetabled " \
      "to teach during the autumn term?"
    ) { choose "20 hours or more each week" }

    click_on "Continue"

    within_fieldset(
      "Does Edna Krabappel spend at least half of their timetabled teaching " \
      "hours delivering 16 to 19 study programmes, T Levels, or 16 to 19 " \
      "apprenticeships?"
    ) { choose "Yes" }

    click_on "Continue"

    expect(page).to have_text("Does Edna Krabappel spend at least half of their timetabled teaching time teaching these courses?")

    # list of courses by the claimaint
    expect(page).to have_text("Qualifications approved for funding at level 3 " \
        "and below in the mathematics and statistics (opens in new tab) sector subject area")

    expect(page).to have_text("GCSE in maths, functional skills qualifications " \
      "and other maths qualifications (opens in new tab) approved for teaching to " \
      "16 to 19-year-olds who meet the condition of funding")

    expect(page).to have_text("GCSE physics")

    choose "Yes"
    click_on "Continue"

    # Check answers
    expect(page).to have_text("Claim reference: AB123456")

    expect(
      summary_row("Teaching responsibilities")
    ).to have_content("Yes")

    expect(
      summary_row("In first 5 years of FE teaching")
    ).to have_content("Yes")

    expect(
      summary_row("Teaching qualification")
    ).to have_content("Yes")

    expect(
      summary_row("Contract type")
    ).to have_content("Permanent")

    expect(
      summary_row("Subject to performance measures")
    ).to have_content("No")

    expect(
      summary_row("Subject to disciplinary action")
    ).to have_content("No")

    expect(
      summary_row("Timetabled hours per week")
    ).to have_content("20 hours or more each week")

    expect(
      summary_row("Teaches 16-19-year-olds or those with EHCP")
    ).to have_content("Yes")

    expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
      .to have_content("Yes")

    check(
      "I have read the provider guidance I was sent by email and to the best of my knowledge confirm the information I have provided in this form is correct."
    )

    click_on "Continue"

    expect(page).to have_content("Claim Verified for Edna Krabappel")
  end

  scenario "with custom subjects and courses - No to teaching listed courses" do
    fe_provider = create(
      :school,
      :further_education,
      name: "Springfield College"
    )

    sign_in_to(fe_provider)

    claim = create(
      :claim,
      :submitted,
      :further_education,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
      eligibility_attributes: {
        school: fe_provider,
        teacher_reference_number: "1234567",
        subjects_taught: ["maths", "physics"],
        maths_courses: ["approved_level_321_maths", "gcse_maths"],
        physics_courses: ["gcse_physics"]
      }
    )

    visit(
      edit_further_education_payments_providers_claim_verification_path(claim)
    )

    # Check claim reference appears in the caption
    expect(page).to have_content("Review claim - AB123456")
    # Check claimant name appears in the heading
    expect(page).to have_selector("h1", text: "Edna Krabappel")

    # Open the collapsible details section and check its content
    find("summary", text: "Claim details").click
    within("details[open]") do
      expect(page).to have_content("TRN")
      expect(page).to have_content("1234567")
      expect(page).to have_content("Date submitted")
      expect(page).to have_content("1 October 2025")
    end

    within_fieldset(
      "Is Edna Krabappel a member of staff with teaching responsibilities?"
    ) { choose "Yes" }

    click_on "Continue"

    within_fieldset(
      "Is Edna Krabappel in the first 5 years of their further education " \
      "(FE) teaching career in England?"
    ) { choose "Yes" }

    click_on "Continue"

    within_fieldset("Does Edna Krabappel have a teaching qualification?") do
      choose "Yes"
    end

    click_on "Continue"

    within_fieldset(
      "What type of contract does Edna Krabappel have with " \
      "Springfield College?"
    ) { choose "Permanent" }

    click_on "Continue"

    # Performance and discipline
    within_fieldset(
      "Is Edna Krabappel currently subject to any performance measures?"
    ) { choose "No" }

    within_fieldset(
      "Is Edna Krabappel currently subject to any disciplinary action?"
    ) { choose "No" }

    click_on "Continue"

    # Contracted hours
    within_fieldset(
      "On average, how many hours per week was Edna Krabappel timetabled " \
      "to teach during the autumn term?"
    ) { choose "20 hours or more each week" }

    click_on "Continue"

    within_fieldset(
      "Does Edna Krabappel spend at least half of their timetabled teaching " \
      "hours delivering 16 to 19 study programmes, T Levels, or 16 to 19 " \
      "apprenticeships?"
    ) { choose "Yes" }

    click_on "Continue"

    expect(page).to have_text("Does Edna Krabappel spend at least half of their timetabled teaching time teaching these courses?")

    # list of courses by the claimaint
    expect(page).to have_text("Qualifications approved for funding at level 3 " \
        "and below in the mathematics and statistics (opens in new tab) sector subject area")

    expect(page).to have_text("GCSE in maths, functional skills qualifications " \
      "and other maths qualifications (opens in new tab) approved for teaching to " \
      "16 to 19-year-olds who meet the condition of funding")

    expect(page).to have_text("GCSE physics")

    choose "No"
    click_on "Continue"

    # Check answers
    expect(page).to have_text("Claim reference: AB123456")

    expect(
      summary_row("Teaching responsibilities")
    ).to have_content("Yes")

    expect(
      summary_row("In first 5 years of FE teaching")
    ).to have_content("Yes")

    expect(
      summary_row("Teaching qualification")
    ).to have_content("Yes")

    expect(
      summary_row("Contract type")
    ).to have_content("Permanent")

    expect(
      summary_row("Subject to performance measures")
    ).to have_content("No")

    expect(
      summary_row("Subject to disciplinary action")
    ).to have_content("No")

    expect(
      summary_row("Timetabled hours per week")
    ).to have_content("20 hours or more each week")

    expect(
      summary_row("Teaches 16-19-year-olds or those with EHCP")
    ).to have_content("Yes")

    # Subject areas answers
    expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
      .to have_content("No")

    check(
      "I have read the provider guidance I was sent by email and to the best of my knowledge confirm the information I have provided in this form is correct."
    )

    click_on "Continue"

    expect(page).to have_content("Claim Verified for Edna Krabappel")
  end

  def summary_row(label)
    find("div.govuk-summary-list__row", text: label)
  end

  def sign_in_to(fe_provider)
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

    visit new_further_education_payments_providers_session_path

    click_on "Start now"
  end
end
