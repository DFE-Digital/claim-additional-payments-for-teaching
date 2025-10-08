require "rails_helper"

RSpec.feature "Provider verifying claims" do
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

      expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
        .to have_content("Not answered")

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

      # Check claim reference in header
      expect(page).to have_content("Review claim - AB123456")

      # Check claimant name in heading
      expect(page).to have_css("h1", text: "Edna Krabappel")

      # Check if claim details are visible (govuk_details might already be expanded in tests)
      # Try to find the summary element first
      if page.has_css?("summary", text: "Claim details", wait: 0)
        # Expand claim details dropdown if it exists
        find("summary", text: "Claim details").click
      end

      # Check details in the dropdown
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 October 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
      ) { choose "Yes" }
      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end
      click_on "Continue"

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Permanent" }
      click_on "Continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any " \
        "formal performance measures as a result of continuous poor " \
        "teaching standards?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      click_on "Continue"

      # Contracted hours
      within_fieldset(
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the autumn term?"
      ) { choose "20 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel spend at least half of their " \
        "timetabled teaching hours teaching students funded through the " \
        "16 to 19 education funding system or apprentices aged 16 to 19?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their spring term timetabled teaching time teaching these courses?"

      # list of courses by the claimaint
      expect(page).to have_text("Qualifications approved for funding at level 3 " \
        "and below in the mathematics and statistics (opens in new tab) sector subject area")

      expect(page).to have_text("GCSE in maths, functional skills qualifications " \
        "and other maths qualifications (opens in new tab) approved for teaching to " \
        "16 to 19-year-olds who meet the condition of funding")

      expect(page).to have_text("GCSE physics")

      choose "Yes"
      click_on "Continue"

      expect(page).to have_text("Is Edna Krabappel expected to continue to be employed at " \
        "Springfield College until the end of the academic year")

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
      ).to have_content("20 hours or more per week")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Yes")

      expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
        .to have_content("Yes")

      expect(
        summary_row("Employed until end of academic year")
      ).to have_content("Yes")

      check(
        "Please ensure your answers are accurate to the best of " \
        "your knowledge. While the DfE runs its own checks, this " \
        "claim is approved or rejected based on your answers. DfE " \
        "will audit approved claims. If any of your teachers receive " \
        "payments that are later found to be ineligible, we will take " \
        "steps to recover the payment."
      )

      click_on "Continue"

      expect(page).to have_content("Verification form for Edna Krabappel sent to DfE")
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

      # Check claim reference in header
      expect(page).to have_content("Review claim - AB123456")

      # Check claimant name in heading
      expect(page).to have_css("h1", text: "Edna Krabappel")

      # Check if claim details are visible (govuk_details might already be expanded in tests)
      # Try to find the summary element first
      if page.has_css?("summary", text: "Claim details", wait: 0)
        # Expand claim details dropdown if it exists
        find("summary", text: "Claim details").click
      end

      # Check details in the dropdown
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 March 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }
      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
      ) { choose "Yes" }
      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end
      click_on "Continue"

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Fixed-term" }
      click_on "Continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      ) { choose "Yes" }

      click_on "Continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any " \
        "formal performance measures as a result of continuous poor " \
        "teaching standards?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      click_on "Continue"

      # Contracted hours
      within_fieldset(
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the spring term?"
      ) { choose "20 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel spend at least half of their " \
        "timetabled teaching hours teaching students funded through the " \
        "16 to 19 education funding system or apprentices aged 16 to 19?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their spring term timetabled teaching time teaching these courses?"

      # list of courses by the claimaint
      expect(page).to have_text("Qualifications approved for funding at level 3 " \
        "and below in the building and construction (opens in new tab) sector subject area")

      choose "Yes"
      click_on "Continue"

      expect(page).to have_text("Is Edna Krabappel expected to continue to be employed at " \
        "Springfield College until the end of the academic year")

      choose "No"
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
      ).to have_content "Yes"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(
        summary_row("Timetabled hours per week")
      ).to have_content("20 hours or more per week")

      expect(
        summary_row("Teaches 16-19-year-olds or those with EHCP")
      ).to have_content("Yes")

      expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
        .to have_content("Yes")

      expect(
        summary_row("Employed until end of academic year")
      ).to have_content("No")

      check(
        "Please ensure your answers are accurate to the best of " \
        "your knowledge. While the DfE runs its own checks, this " \
        "claim is approved or rejected based on your answers. DfE " \
        "will audit approved claims. If any of your teachers receive " \
        "payments that are later found to be ineligible, we will take " \
        "steps to recover the payment."
      )

      click_on "Continue"

      expect(page).to have_content("Verification form for Edna Krabappel sent to DfE")
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

      # Check claim reference in header
      expect(page).to have_content("Review claim - AB123456")

      # Check claimant name in heading
      expect(page).to have_css("h1", text: "Edna Krabappel")

      # Check if claim details are visible (govuk_details might already be expanded in tests)
      # Try to find the summary element first
      if page.has_css?("summary", text: "Claim details", wait: 0)
        # Expand claim details dropdown if it exists
        find("summary", text: "Claim details").click
      end

      # Check details in the dropdown
      expect(summary_row("TRN")).to have_content("1234567")
      expect(summary_row("Date submitted")).to have_content("1 May 2025")

      within_fieldset(
        "Is Edna Krabappel a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
      ) { choose "Yes" }

      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end

      click_on "Continue"

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Variable hours" }

      click_on "Continue"

      # Second screen with additional questions for variable hours contracts
      within_fieldset(
        "Has Edna Krabappel worked at Springfield College for the whole of " \
        "the spring term?"
      ) { choose "Yes" }

      click_on "Continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any " \
        "formal performance measures as a result of continuous poor " \
        "teaching standards?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      click_on "Continue"

      # Contracted hours
      within_fieldset(
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the summer term?"
      ) { choose "20 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel spend at least half of their " \
        "timetabled teaching hours teaching students funded through the " \
        "16 to 19 education funding system or apprentices aged 16 to 19?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their spring term timetabled teaching time teaching these courses?"

      # list of courses by the claimaint
      expect(page).to have_text("Level 2 or level 3 apprenticeships in the " \
        "digital occupational route (opens in new tab)")

      expect(page).to have_text("A or AS level chemistry")

      choose "Yes"
      click_on "Continue"

      expect(page).to have_text("Is Edna Krabappel expected to continue to be employed at " \
        "Springfield College until the end of the academic year")

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
        summary_row(
          "Worked at Springfield College for the whole of the spring term"
        )
      ).to have_content "Yes"

      expect(
        summary_row("Subject to performance measures")
      ).to have_content("No")

      expect(
        summary_row("Subject to disciplinary action")
      ).to have_content("No")

      expect(summary_row("Spend at least half timetabled teaching time teaching relevant courses"))
        .to have_content("Yes")

      expect(
        summary_row("Employed until end of academic year")
      ).to have_content("Yes")

      check(
        "Please ensure your answers are accurate to the best of " \
        "your knowledge. While the DfE runs its own checks, this " \
        "claim is approved or rejected based on your answers. DfE " \
        "will audit approved claims. If any of your teachers receive " \
        "payments that are later found to be ineligible, we will take " \
        "steps to recover the payment."
      )

      click_on "Continue"

      expect(page).to have_content("Verification form for Edna Krabappel sent to DfE")
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
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
      ) { choose "Yes" }
      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end
      click_on "Continue"

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Variable" }
      click_on "Continue"

      # Third variable hours screen
      within_fieldset(
        "Has Edna Krabappel worked at Springfield College for the whole of " \
        "the spring term?"
      ) { choose "Yes" }

      click_on "Continue"

      # Performance and discipline
      within_fieldset(
        "Is Edna Krabappel currently subject to any " \
        "formal performance measures as a result of continuous poor " \
        "teaching standards?"
      ) { choose "No" }

      within_fieldset(
        "Is Edna Krabappel currently subject to any disciplinary action?"
      ) { choose "No" }

      click_on "Continue"

      # Contracted hours
      within_fieldset(
        "On average, how many hours per week was Edna Krabappel timetabled " \
        "to teach during the autumn term?"
      ) { choose "20 hours or more per week" }

      click_on "Continue"

      within_fieldset(
        "Did Edna Krabappel spend at least half of their " \
        "timetabled teaching hours teaching students funded through the " \
        "16 to 19 education funding system or apprentices aged 16 to 19?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(page).to have_text "Does Edna Krabappel spend at least half of " \
        "their spring term timetabled teaching time teaching these courses?"

      # list of courses by the claimaint
      expect(page).to have_text("Qualifications approved for funding at level 3 " \
        "and below in the mathematics and statistics (opens in new tab) sector subject area")

      expect(page).to have_text("GCSE in maths, functional skills qualifications " \
        "and other maths qualifications (opens in new tab) approved for teaching to " \
        "16 to 19-year-olds who meet the condition of funding")

      expect(page).to have_text("GCSE physics")

      choose "Yes"
      click_on "Continue"

      expect(page).to have_text("Is Edna Krabappel expected to continue to be employed at " \
        "Springfield College until the end of the academic year")

      choose "Yes"
      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Variable hours")

      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Permanent" }
      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Permanent")

      # Change contract type to Fixed-term
      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Fixed-term" }
      click_on "Continue"

      # Second screen with additional questions for fixed term contracts
      within_fieldset(
        "Is Edna Krabappel's fixed-term contract for the full 2025 to 2026 " \
        "academic year?"
      ) { choose "No" }

      click_on "Continue"

      within_fieldset(
        "Has Edna Krabappel worked at Springfield College for the whole of " \
        "the spring term?"
      ) { choose "Yes" }

      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Fixed-term")

      expect(
        summary_row("Contract covers full academic year")
      ).to have_content "No"

      expect(
        summary_row(
          "Worked at Springfield College for the whole of the spring term"
        )
      ).to have_content("Yes")

      # Change contract type to Variable hours
      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Variable hours" }

      click_on "Continue"

      expect(summary_row("Contract type")).to have_content("Variable hours")

      expect(
        summary_row(
          "Worked at Springfield College for the whole of the spring term"
        )
      ).to have_content("Yes")

      # Change contract type to Employed by another organisation
      within(summary_row("Contract type")) do
        click_on "Change"
      end

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) do
        choose(
          "Does not currently have a direct contract of employment with Springfield College"
        )
      end
      click_on "Continue"

      expect(summary_row("Contract type")).to have_content(
        "Does not currently have a direct contract of employment"
      )

      expect(page).not_to have_content("At least 2.5 hours per week")

      expect(page).not_to have_content("Variable hours in academic year")

      expect(page).not_to have_content("Contract covers full academic year")

      # Change continued employment answer from Yes to No
      expect(
        summary_row("Employed until end of academic year")
      ).to have_content("Yes")

      within(summary_row("Employed until end of academic year")) do
        click_on "Change"
      end

      expect(page).to have_text("Is Edna Krabappel expected to continue to be employed at " \
        "Springfield College until the end of the academic year")

      choose "No"
      click_on "Continue"

      expect(
        summary_row("Employed until end of academic year")
      ).to have_content("No")
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
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
      ) { choose "Yes" }
      click_on "Continue"

      within_fieldset("Does Edna Krabappel have a teaching qualification?") do
        choose "Yes"
      end
      click_on "Continue"

      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
        "Springfield College?"
      ) { choose "Variable" }
      click_on "Continue"

      # Expect to see the first variable hours specific question
      expect(page).to have_content(
        "Has Edna Krabappel worked at Springfield College for the whole of the spring term?"
      )
      click_on "Back"

      # Now we're back to the contract type page
      within_fieldset(
        "What type of contract does Edna Krabappel have directly with " \
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
        "Did Edna Krabappel start their FE teaching career in England during " \
        "September 2023 to August 2024?"
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
        "What type of contract does Edna Krabappel have directly with " \
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

      # Status badge is now in the header
      expect(page).to have_css(".govuk-tag", text: "Not started")
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

      # Status badge is now in the header
      expect(page).to have_css(".govuk-tag", text: "Not started")

      within_fieldset(
        "Is Lisa Simpson a member of staff with teaching responsibilities?"
      ) { choose "Yes" }

      click_on "Save and come back later"

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      # Status badge is now in the header
      expect(page).to have_css(".govuk-tag", text: "In progress")
    end
  end

  context "when the provider verifies a claim which has failed idv" do
    context "when the claim has not started employment checks" do
      context "when the claimant does not work at the school" do
        it "allows the provider to mark the claim as not eligible" do
          fe_provider = create(
            :school,
            :further_education,
            name: "Springfield College"
          )

          claim = create(
            :claim,
            :submitted,
            :further_education,
            :failed_onelogin_idv,
            first_name: "Edna",
            surname: "Krabappel",
            eligibility_attributes: {
              school: fe_provider
            }
          )

          sign_in_to(fe_provider)

          click_on claim.full_name

          expect(page).to have_content("Employment check needed for this claim")

          click_on "Continue"

          within_fieldset("Does Springfield College employ Edna Krabappel?") do
            choose "No"
          end

          click_on "Continue"

          expect(page).to have_content("Done")
          expect(page).to have_content(
            "Employment check for Edna Krabappel complete"
          )
          expect(page).to have_content(
            "You've told us this applicant does not work at Springfield College"
          )

          visit further_education_payments_providers_claims_path

          expect(page).not_to have_content(claim.full_name)

          visit further_education_payments_providers_verified_claims_path

          expect(page).to have_content(claim.full_name)
          expect(page).to have_content(claim.reference)

          within table_row(claim.reference) do
            expect(page).to have_content("Rejected")
          end

          click_on claim.full_name

          expect(page).to have_content("Claim reference: #{claim.reference}")

          expect(page).to have_content(
            "You‘ve told us this applicant does not work at Springfield College. " \
            "We‘ll let the claimant know this claim has been unsuccessful."
          )
        end
      end

      context "when the claimant works at the school" do
        it "allows the provider to verify employment" do
          fe_provider = create(
            :school,
            :further_education,
            name: "Springfield College"
          )

          claim = create(
            :claim,
            :submitted,
            :further_education,
            :failed_onelogin_idv,
            first_name: "Edna",
            surname: "Krabappel",
            eligibility_attributes: {
              school: fe_provider
            }
          )

          sign_in_to(fe_provider)

          click_on claim.full_name

          expect(page).to have_content("Employment check needed for this claim")

          click_on "Continue"

          within_fieldset("Does Springfield College employ Edna Krabappel?") do
            choose "Yes"
          end

          click_on "Continue"

          expect(page).to have_content("About Edna Krabappel")

          within_fieldset("Enter their date of birth") do
            fill_in "Day", with: "3"
            fill_in "Month", with: "7"
            fill_in "Year", with: "1945"
          end

          fill_in("Enter their postcode", with: "TE57 1NG")

          fill_in("Enter their National Insurance number", with: "QQ123456C")

          within_fieldset(
            "Do these bank details match what you have for Edna Krabappel?"
          ) { choose "Yes" }

          fill_in(
            "Email address",
            with: "edna.krabbappel@springfield-college.edu"
          )

          click_on "Continue"

          expect(page).to have_content("Claim reference: #{claim.reference}")

          check(
            "To the best of my knowledge, I confirm that the information " \
            "provided in this form is correct."
          )

          click_on "Confirm and send"

          expect(page).to have_content("Done")
          expect(page).to have_content(
            "Employment check for Edna Krabappel complete"
          )

          # Expect to be on the first page of the verification journey
          expect(page).to have_content(
            "Review claim - #{claim.reference}"
          )

          expect(page).to have_content(
            "Is Edna Krabappel a member of staff with teaching responsibilities?"
          )

          # Check that subsequent visits to the claim redirect to the first step
          # of the verification flow
          visit further_education_payments_providers_claims_path

          click_on claim.full_name

          expect(page).to have_content(
            "Is Edna Krabappel a member of staff with teaching responsibilities?"
          )
        end
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
      Policies::FurtherEducationPayments::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    visit new_further_education_payments_providers_session_path

    click_on "Start now"
  end

  def table_row(claim_reference)
    find("table tbody tr", text: claim_reference)
  end
end
