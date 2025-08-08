require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    FeatureFlag.enable!(:provider_dashboard)
  end

  context "when a provider opens a claim assigned to another user wants to continue verifiying" do
    it "allows them to re-assign to themself" do
      fe_provider = create(
        :school,
        :further_education,
        name: "Springfield College"
      )

      sign_in_to(fe_provider)

      another_user = create(:dfe_signin_user, given_name: "Boris", family_name: "Admin")

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
          physics_courses: ["gcse_physics"],
          provider_assigned_to_id: another_user.id
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to have_content("Do you want to continue verifying this claim?")
      expect(page).to have_content("This claim was started by Boris Admin")

      choose "Yes"
      click_on "Continue"

      expect(page).to have_content("Role and experience")

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # Shouldn't hit the "Do you want to continue verifying this claim?" page as it's now assigned
      expect(page).to have_content("Role and experience")
    end
  end

  context "when a provider opens a claim assigned to another user and wants to read only" do
    it "allows them to view it read-only" do
      fe_provider = create(
        :school,
        :further_education,
        name: "Springfield College"
      )

      sign_in_to(fe_provider)

      another_user = create(:dfe_signin_user, given_name: "Boris", family_name: "Admin")

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
          physics_courses: ["gcse_physics"],
          provider_assigned_to_id: another_user.id,
          # For it to be assigned the 1st question would have been answered
          # to trigger the initial assignment
          provider_verification_teaching_responsibilities: true
        }
      )

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to have_content("Do you want to continue verifying this claim?")
      expect(page).to have_content("This claim was started by Boris Admin")

      choose "No, I just want to see the claim"
      click_on "Continue"

      expect(page).to have_text("Claim: read only mode")
      expect(page).to have_text("Claim reference: AB123456")
      expect(page).to have_content("This claim was started by Boris Admin")

      expect(
        summary_row("Teaching responsibilities")
      ).to have_content("Yes")

      expect(
        summary_row("In first 5 years of FE teaching")
      ).to have_content("Not answered")

      expect(
        summary_row("Teaching qualification")
      ).to have_content("Not answered")

      expect(
        summary_row("Contract type")
      ).to have_content("Not answered")

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("Not answered")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("Not answered")

      expect(
        summary_row("Timetabled hours per week")
      ).to have_content("Not answered")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Not answered")

      expect(
        summary_row("Teaches Level 3 courses")
      ).to have_content("Not answered")

      # Go back to the claim, it should still be assigned to the previous user and asks again
      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to have_content("Do you want to continue verifying this claim?")
      expect(page).to have_content("This claim was started by Boris Admin")
    end
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

      within_fieldset(
        "For at least half of their timetabled teaching hours, does " \
        "Edna Krabappel teach:"
      ) { choose "Yes" }
      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their timetabled teaching time teaching these courses?"
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

      expect(summary_row("Teaches Level 3 courses")).to have_content("Yes")

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
        text: "Completed"
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
        submitted_at: DateTime.new(2025, 3, 1, 9, 0, 0),
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
      expect(summary_row("Date submitted")).to have_content("1 March 2025")

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
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
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
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the spring term?"
      ) { choose "20 hours or more each week" }

      click_on "Continue"

      within_fieldset(
        "Does Edna Krabappel spend at least half of their timetabled teaching " \
        "hours delivering 16 to 19 study programmes, T Levels, or 16 to 19 " \
        "apprenticeships?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }
      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their timetabled teaching time teaching these courses?"
      choose "Yes"
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
        summary_row("Contract type")
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
      ).to have_content("20 hours or more each week")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Yes")

      expect(summary_row("Teaches Level 3 courses")).to have_content("Yes")

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
        submitted_at: DateTime.new(2025, 5, 1, 9, 0, 0),
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
      expect(summary_row("Date submitted")).to have_content("1 May 2025")

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
        "Is Edna Krabappel timetabled to teach at least 2.5 hours per week at " \
        "Springfield College in the [spring_or_summer] term?"
      ) { choose "Yes" }

      click_on "Continue"

      # Third screen with additional questions for variable hours contracts
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "full academic term?"
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
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the summer term?"
      ) { choose "20 hours or more each week" }

      click_on "Continue"

      within_fieldset(
        "Does Edna Krabappel spend at least half of their timetabled teaching " \
        "hours delivering 16 to 19 study programmes, T Levels, or 16 to 19 " \
        "apprenticeships?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }
      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their timetabled teaching time teaching these courses?"
      choose "Yes"
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
        summary_row("Contract type")
      ).to have_content "Variable hours"

      expect(
        summary_row("Timetabled hours in term")
      ).to have_content "Yes"

      expect(
        summary_row("Variable contract academic term")
      ).to have_content "Yes"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(summary_row("Teaches Level 3 courses")).to have_content("Yes")

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
        "Is Edna Krabappel timetabled to teach at least 2.5 hours per week at " \
        "Springfield College in the [spring_or_summer] term?"
      ) { choose "Yes" }

      click_on "Continue"

      # Third variable hours screen
      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "full academic term?"
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

      within_fieldset(
        "For at least half of their timetabled teaching hours, does Edna " \
        "Krabappel teach:"
      ) { choose "Yes" }
      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their timetabled teaching time teaching these courses?"
      choose "Yes"
      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Variable hours")

      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Permanent" }

      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Permanent")

      # Change contract type to Fixed-term
      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Fixed-term" }

      click_on "Continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Fixed-term")

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "No"

      # Change contract type to Variable hours
      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have with " \
        "Springfield College?"
      ) { choose "Variable hours" }

      click_on "Continue"

      within_fieldset(
        "Is Edna Krabappel timetabled to teach at least 2.5 hours per week at " \
        "Springfield College in the [spring_or_summer] term?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "Has Edna Krabappel taught at Springfield College for at least one " \
        "full academic term?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Variable hours")

      expect(summary_row("Timetabled hours in term")).to have_content("Yes")

      expect(
        summary_row("Variable contract academic term")
      ).to have_content("Yes")

      # Change contract type to Employed by another organisation
      within(summary_row("Contract type")) do
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

      expect(summary_row("Contract type")).to have_content(
        "Employed by another organisation (for example, an agency or contractor)"
      )

      expect(page).not_to have_content("At least 2.5 hours per week")

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

      # Expect to see the first variable hours specific question
      expect(page).to have_content(
        "Is Edna Krabappel timetabled to teach at least 2.5 hours per week at " \
        "Springfield College in the [spring_or_summer] term?"
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
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      )

      within_fieldset(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      click_on "Continue"

      # Performance and discipline page
      click_on "Back"

      # Expect to see fixed term specific question
      expect(page).to have_content(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
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
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      )

      click_on "Save and come back later"

      expect(page).to have_content("Progress saved")

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # First incomplete form
      expect(page).to have_content(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
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
end
