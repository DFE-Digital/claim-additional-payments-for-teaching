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
        onelogin_idv_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        identity_confirmed_with_onelogin: false,
        eligibility_attributes: {
          school: fe_provider,
          teaching_hours_per_week: "between_2_5_and_12",
          contract_type: "permanent",
          fixed_term_full_year: false,
          subjects_taught: ["engineering_manufacturing"],
          engineering_manufacturing_courses: [
            "approved_level_321_transportation",
            "level2_3_apprenticeship"
          ],
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within "#claim-details" do
        expect(page).to have_text("Not started")
      end

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
        date_of_birth: Date.new(1945, 7, 3),
        reference: "AB123456",
        submitted_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        onelogin_idv_at: DateTime.new(2025, 10, 1, 9, 0, 0),
        identity_confirmed_with_onelogin: false,
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: {
          school: fe_provider,
          teaching_hours_per_week: "between_2_5_and_12",
          contract_type: "fixed_term",
          fixed_term_full_year: true,
          subjects_taught: ["engineering_manufacturing"],
          engineering_manufacturing_courses: [
            "approved_level_321_transportation",
            "level2_3_apprenticeship"
          ],
          teacher_reference_number: "1234567"
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within "#claim-details" do
        expect(page).to have_text("Not started")
      end

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
    end
  end

  def summary_row(label)
    find("dt", text: label).sibling("dd")
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
