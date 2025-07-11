require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    FeatureFlag.enable!(:provider_dashboard)
  end

  context "when a provider verifies a permanent contract claim" do
    it "allows them to verify the claim" do
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
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(summary_row("Claim reference")).to have_content("AB123456")
      expect(summary_row("Claimant name")).to have_content("Edna Krabappel")
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 October 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Permanent" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any performance measures?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      expect(page).to have_text("Claim reference: AB123456")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content("yes")

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content("yes")

      expect(
        summary_row("Teaching qualification")
      ).to have_content("yes")

      expect(
        summary_row("Type of contract")
      ).to have_content("Permanent")

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("no")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("no")
    end
  end

  context "when a provider verifies a fixed term contract claim" do
    it "allows them to verify the claim with additional questions" do
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
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: {
          school: fe_provider,
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(summary_row("Claim reference")).to have_content("AB123456")
      expect(summary_row("Claimant name")).to have_content("Edna Krabappel")
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 October 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any performance measures?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      expect(page).to have_text("Claim reference: AB123456")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content "yes"

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content "yes"

      expect(
        summary_row("Teaching qualification")
      ).to have_content "yes"

      expect(
        summary_row("Type of contract")
      ).to have_content "Fixed-term"

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "no"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("no")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("no")
    end
  end

  context "when a provider verifies a variable hours contract claim" do
    it "allows them to verify the claim with additional questions" do
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
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        eligibility_attributes: {
          school: fe_provider,
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(summary_row("Claim reference")).to have_content("AB123456")
      expect(summary_row("Claimant name")).to have_content("Edna Krabappel")
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 October 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Variable hours" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Second screen with additional questions for variable hours contracts
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      ) { choose "Yes" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any performance measures?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      expect(page).to have_text("Claim reference: AB123456")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content "yes"

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content "yes"

      expect(
        summary_row("Teaching qualification")
      ).to have_content "yes"

      expect(
        summary_row("Type of contract")
      ).to have_content "Variable hours"

      expect(
        summary_row("Variable hours in academic year")
      ).to have_content "yes"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("no")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("no")
    end
  end

  context "changing answers" do
    it "allows the provider to change answers" do
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
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: {
          school: fe_provider,
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Variable" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Second variable hours screen
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      ) { choose "Yes" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any performance measures?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Check answers page
      expect(summary_row("Type of contract")).to have_content("Variable hours")

      within(summary_card("Role and experience")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Permanent" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      expect(summary_row("Type of contract")).to have_content("Permanent")

      # Change contract type to Fixed-term
      within(summary_card("Role and experience")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      expect(summary_row("Type of contract")).to have_content("Fixed-term")

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "no"

      # Change answer on second page of fixed term contract
      within(summary_card("Role and experience")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { expect(page).to have_checked_field("Fixed-term") }

      click_on "Save and continue"

      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      click_on "Save and continue"

      expect(summary_row("Type of contract")).to have_content("Fixed-term")

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "yes"
    end
  end

  context "when the provider clicks a back link" do
    it "takes them to the previous page" do
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
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: {
          school: fe_provider,
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Variable" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Expect to see variable hours specific question
      expect(page).to have_content(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      )

      click_on "Back"

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Expect to see fixed term specific question
      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )

      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      # Performance and discipline page
      click_on "Back"

      # Expect to see fixed term specific question
      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )
    end
  end

  context "when saving and returning to the claim later" do
    it "preserves the answers" do
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
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: {
          school: fe_provider,
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      within_fieldset("Have you completed this section?") do
        choose "No, I want to come back to it later"
      end

      click_on "Save and continue"

      expect(page).to have_content("Progress saved")

      click_on "Return to dashboard"

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { expect(page).to have_checked_field("Yes") }

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { expect(page).to have_checked_field("Yes") }

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        expect(page).to have_checked_field("Yes")
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      within_fieldset("Have you completed this section?") do
        choose "Yes"
      end

      click_on "Save and continue"

      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      within_fieldset("Have you completed this section?") do
        choose "No"
      end

      click_on "Save and continue"

      expect(page).to have_content("Progress saved")

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # Role and experience form
      click_on "Save and continue"

      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )
    end
  end

  def summary_row(label)
    find("dt", text: label).sibling("dd")
  end

  def summary_card(heading)
    match = all(".govuk-summary-card").detect do |card|
      card.find(".govuk-summary-card__title").text == heading
    end

    raise "Couldn't find summary card with title #{heading}" unless match

    match
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
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    visit new_further_education_payments_providers_session_path

    click_on "Start now"
  end
end
