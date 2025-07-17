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
          teacher_reference_number: "1234567",
          subjects_taught: ["maths", "physics"],
          maths_courses: ["approved_level_321_maths", "gcse_maths"],
          physics_courses: ["gcse_physics"]
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
        "On average, how many hours per week is Edna Krabappel timetabled " \
        "to teach during the current term?"
      ) { choose "12 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
        "age 25 with an Education, Health and Care Plan (EHCP)?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach:"
      ) { choose "Yes" }

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
        summary_row("Type of contract")
      ).to have_content("Permanent")

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(
        summary_row("Timetabled hours per week")
      ).to have_content("12 hours or more per week")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Yes")

      expect(
        summary_row("Teaches approved qualification in maths and physics")
      ).to have_content("Yes")

      check(
        "I have read the provider guidance I was sent by email and to the " \
        "best of my knowledge confirm the information I have provided in " \
        "this form is correct."
      )

      click_on "Continue"

      expect(page).to have_content("Claim Verified for Edna Krabappel")
      expect(
        page.current_path
      ).to eql("/further-education-payments/providers/verified-claims")
      expect(page).to have_css(
        "table tbody tr:first-child td:nth-child(4)",
        text: "Pending"
      )
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
          teacher_reference_number: "1234567",
          subjects_taught: ["building_construction"],
          building_construction_courses: ["level3_buildingconstruction_approved"]
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
      ) { choose "Fixed-term" }

      click_on "Continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

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
        "On average, how many hours per week is Edna Krabappel timetabled " \
        "to teach during the current term?"
      ) { choose "12 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
        "age 25 with an Education, Health and Care Plan (EHCP)?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }

      click_on "Continue"

      # Check answers
      expect(page).to have_text("Claim reference: AB123456")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content "Yes"

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content "Yes"

      expect(
        summary_row("Teaching qualification")
      ).to have_content "Yes"

      expect(
        summary_row("Type of contract")
      ).to have_content "Fixed-term"

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "No"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(
        summary_row("Timetabled hours per week")
      ).to have_content("12 hours or more per week")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Yes")

      expect(
        summary_row("Teaches approved qualification in building and construction")
      ).to have_content("Yes")

      check(
        "I have read the provider guidance I was sent by email and to the " \
        "best of my knowledge confirm the information I have provided in " \
        "this form is correct."
      )

      click_on "Continue"

      expect(page).to have_content("Claim Verified for Edna Krabappel")
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
          teacher_reference_number: "1234567",
          subjects_taught: ["computing", "chemistry"],
          computing_courses: ["level2_3_apprenticeship"],
          chemistry_courses: ["alevel_chemistry"]
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
      ) { choose "Variable hours" }

      click_on "Continue"

      # Second screen with additional questions for variable hours contracts
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      ) { choose "Yes" }

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
        "On average, how many hours per week is Edna Krabappel timetabled " \
        "to teach during the current term?"
      ) { choose "12 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
        "age 25 with an Education, Health and Care Plan (EHCP)?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }

      click_on "Continue"

      # Check answers

      expect(page).to have_text("Claim reference: AB123456")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content "Yes"

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content "Yes"

      expect(
        summary_row("Teaching qualification")
      ).to have_content "Yes"

      expect(
        summary_row("Type of contract")
      ).to have_content "Variable hours"

      expect(
        summary_row("Variable hours in academic year")
      ).to have_content "Yes"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(
        summary_row(
          "Teaches approved qualification in computing, including digital " \
          "and ict and chemistry"
        )
      ).to have_content("Yes")

      check(
        "I have read the provider guidance I was sent by email and to the " \
        "best of my knowledge confirm the information I have provided in " \
        "this form is correct."
      )

      click_on "Continue"

      expect(page).to have_content("Claim Verified for Edna Krabappel")
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
      ) { choose "Variable" }

      click_on "Continue"

      # Second variable hours screen
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      ) { choose "Yes" }

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
        "On average, how many hours per week is Edna Krabappel timetabled " \
        "to teach during the current term?"
      ) { choose "12 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach 16- to 19-year-olds, including those up to " \
        "age 25 with an Education, Health and Care Plan (EHCP)?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }

      click_on "Continue"

      expect(summary_row("Type of contract")).to have_content("Variable hours")

      within(summary_row("Type of contract")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Permanent" }

      click_on "Continue"

      expect(summary_row("Type of contract")).to have_content("Permanent")

      # Change contract type to Fixed-term
      within(summary_row("Type of contract")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      click_on "Continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

      click_on "Continue"

      expect(summary_row("Type of contract")).to have_content("Fixed-term")

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "No"

      # Change contract type to Variable hours
      within(summary_row("Type of contract")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Variable hours" }

      click_on "Continue"

      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(summary_row("Type of contract")).to have_content("Variable hours")
      expect(
        summary_row("Variable hours in academic year")
      ).to have_content("Yes")

      # Change contract type to Employed by another organisation
      within(summary_row("Type of contract")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) do
        choose(
          "Employed by another organisation (for example, an agency or contractor)"
        )
      end

      click_on "Continue"

      expect(summary_row("Type of contract")).to have_content(
        "Employed by another organisation (for example, an agency or contractor)"
      )

      expect(page).not_to have_content("Variable hours in academic year")

      expect(page).not_to have_content("Contract covers full academic year")
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
      ) { choose "Variable" }

      click_on "Continue"

      # Expect to see variable hours specific question
      expect(page).to have_content(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "academic term?"
      )

      click_on "Back"

      # Now we're back to the contract type page
      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      click_on "Continue"

      # Expect to see fixed term specific question
      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )

      within_fieldset(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      click_on "Continue"

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

      click_on "Continue"

      within_fieldset(
        "Is Edna Krabappel in the first 5 years of their further education " \
        "(FE) teaching career in England?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      click_on "Save and come back later"

      expect(page).to have_content("Progress saved")

      click_on "Return to dashboard"

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # Should go to the contract type page since the first two pages are completed
      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      click_on "Continue"

      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )

      click_on "Save and come back later"

      expect(page).to have_content("Progress saved")

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # First incomplete form
      expect(page).to have_content(
        "Does Edna Krabappel fixed-term contract cover the full 2025 to 2026 " \
        "academic year?"
      )
    end
  end

  context "when a provider attempts to edit an already verified claim" do
    it "prevents editing of the claim" do
      fe_provider = create(
        :school,
        :further_education,
        name: "Springfield College"
      )

      sign_in_to(fe_provider)

      claim = create(
        :claim,
        :further_education,
        :submitted,
        eligibility_trait: :provider_verification_completed,
        eligibility_attributes: {
          school: fe_provider
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to have_content("This claim has already been verified")
      expect(page).not_to have_button("Continue")
    end
  end

  context "status badge display" do
    it "shows 'Not started' when no verification has been done" do
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
        first_name: "Bart",
        surname: "Simpson",
        eligibility_attributes: {
          school: fe_provider
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within("#claim-details") do
        expect(page).to have_content("Not started")
      end
    end

    it "shows 'In progress' after saving some verification data" do
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
        first_name: "Lisa",
        surname: "Simpson",
        eligibility_attributes: {
          school: fe_provider
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within("#claim-details") do
        expect(page).to have_content("Not started")
      end

      within_fieldset(
        "Is Lisa Simpson a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      click_on "Save and come back later"

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      within("#claim-details") do
        expect(page).to have_content("In progress")
      end
    end
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

  def summary_row(label)
    find("div.govuk-summary-list__row", text: label)
  end
end
