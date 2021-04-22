require "rails_helper"

RSpec.feature "Maths & Physics claims" do
  [true, false].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims for Maths & Physics payment with JavaScript #{js_status}", js: javascript_enabled do
      visit new_claim_path(MathsAndPhysics.routing_name)
      expect(page).to have_link(href: MathsAndPhysics.feedback_url)

      expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

      choose "Yes"
      click_on "Continue"

      claim = Claim.order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.teaching_maths_or_physics).to eql true

      expect(page).to have_text(I18n.t("questions.current_school"))
      choose_school schools(:penistone_grammar_school)
      expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

      expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_subject"))
      choose "Science"
      click_on "Continue"
      expect(claim.eligibility.reload.initial_teacher_training_subject).to eql "science"

      expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_subject_specialism"))
      choose "Physics"
      click_on "Continue"
      expect(claim.eligibility.reload.initial_teacher_training_subject_specialism).to eql "physics"

      expect(page).to have_text(I18n.t("questions.qts_award_year"))
      choose_qts_year(:on_or_after_cut_off_date)
      expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_cut_off_date")

      expect(page).to have_text(I18n.t("maths_and_physics.questions.employed_as_supply_teacher"))
      choose "No"
      click_on "Continue"
      expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

      expect(page).to have_text(I18n.t("maths_and_physics.questions.disciplinary_action"))
      choose "No"
      click_on "Continue"
      expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

      expect(page).to have_text(I18n.t("maths_and_physics.questions.formal_performance_action"))
      choose "No"
      click_on "Continue"
      expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false

      expect(page).to have_text("You are eligible to claim a payment for teaching maths or physics")
      click_on "Continue"

      expect(page).to have_text("How we will use the information you provide")
      click_on "Continue"

      expect(page).to have_text(I18n.t("questions.name"))
      fill_in "First name", with: "Sarah"
      fill_in "Middle names", with: "Jennifer"
      fill_in "Last name", with: "Winstanley"
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Sarah")
      expect(claim.middle_name).to eql("Jennifer")
      expect(claim.surname).to eql("Winstanley")

      expect(page).to have_text(I18n.t("questions.address"))
      fill_in_address

      expect(claim.reload.address_line_1).to eql("123 Main Street")
      expect(claim.address_line_2).to eql("Downtown")
      expect(claim.address_line_3).to eql("Twin Peaks")
      expect(claim.address_line_4).to eql("Washington")
      expect(claim.postcode).to eql("M1 7HL")

      expect(page).to have_text(I18n.t("questions.date_of_birth"))
      fill_in "Day", with: "03"
      fill_in "Month", with: "7"
      fill_in "Year", with: "1990"
      click_on "Continue"

      expect(claim.reload.date_of_birth).to eq(Date.new(1990, 7, 3))

      expect(page).to have_text(I18n.t("questions.payroll_gender"))
      choose "Female"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("female")

      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))
      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      expect(page).to have_text(I18n.t("questions.national_insurance_number"))
      fill_in "National Insurance number", with: "QQ123456C"
      click_on "Continue"

      expect(claim.reload.national_insurance_number).to eq("QQ123456C")

      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      answer_student_loan_plan_questions

      expect(claim.reload).to have_student_loan
      expect(claim.student_loan_country).to eq("england")
      expect(claim.student_loan_courses).to eq("one_course")
      expect(claim.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      expect(page).to have_text(I18n.t("questions.email_address"))
      fill_in I18n.t("questions.email_address"), with: "name@example.com"
      click_on "Continue"

      expect(claim.reload.email_address).to eq("name@example.com")

      expect(page).to have_text(I18n.t("questions.bank_details"))

      fill_in "Name on the account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      fill_in "Building society roll number (if you have one)", with: "1234/123456789"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.reload.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")
      expect(claim.building_society_roll_number).to eq("1234/123456789")

      expect(page).to have_text("Check your answers before sending your application")

      stub_geckoboard_dataset_update
      stub_qualified_teaching_status_show(claim: claim)

      freeze_time do
        perform_enqueued_jobs do
          expect {
            click_on "Confirm and send"
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        expect(claim.reload.submitted_at).to eq(Time.zone.now)
      end

      expect(page).to have_text("Claim submitted")
      expect(page).to have_text(claim.reference)
      expect(page).to have_text(claim.email_address)
    end
  end

  scenario "Teacher claims for Maths and Physics, without maths or physics ITT and with a UK degree in maths or physics" do
    # This test was initially written for the purpose of building out this
    # alternative journey. It does not test the whole claims journey but only
    # this part of it. Not sure of the best approach.
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.teaching_maths_or_physics).to eql true

    expect(page).to have_text(I18n.t("questions.current_school"))
    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_subject"))
    choose "None of these subjects"
    click_on "Continue"
    expect(claim.eligibility.reload.initial_teacher_training_subject).to eql "none_of_the_subjects"

    expect(page).to have_text(I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"))
    choose "Yes"
    click_on "Continue"
    expect(claim.eligibility.reload.has_uk_maths_or_physics_degree).to eql "yes"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end

  scenario "Teacher claims for Maths and Physics, without maths or physics ITT and with a non-UK degree in maths or physics" do
    # This test was initially written for the purpose of building out this
    # alternative journey. It does not test the whole claims journey but only
    # this part of it. Not sure of the best approach.
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.teaching_maths_or_physics).to eql true

    expect(page).to have_text(I18n.t("questions.current_school"))
    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_subject"))
    choose "None of these subjects"
    click_on "Continue"
    expect(claim.eligibility.reload.initial_teacher_training_subject).to eql "none_of_the_subjects"

    expect(page).to have_text(I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"))
    choose "I have a non-UK degree in Maths or Physics"
    click_on "Continue"
    expect(claim.eligibility.reload.has_uk_maths_or_physics_degree).to eql "has_non_uk"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end

  scenario "Teacher is still eligible for Maths and Physics without a degree if they are not sure about their ITT specialism" do
    start_maths_and_physics_claim
    choose_school schools(:penistone_grammar_school)

    choose_initial_teacher_training_subject "Science (physics, biology and chemistry)"
    choose_initial_teacher_training_subject_specialism "I’m not sure"

    expect(page).to have_text(I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end

  scenario "Supply teacher claims for Maths and Physics, employed directly by school with a contract to teach for an entire term" do
    # This test was initially written for the purpose of building out this
    # alternative journey. It does not test the whole claims journey but only
    # this part of it. Not sure of the best approach.
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.teaching_maths_or_physics).to eql true

    expect(page).to have_text(I18n.t("questions.current_school"))
    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_subject"))
    choose "Physics"
    click_on "Continue"
    expect(claim.eligibility.reload.initial_teacher_training_subject).to eql "physics"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
    choose_qts_year(:on_or_after_cut_off_date)
    expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_cut_off_date")

    expect(page).to have_text(I18n.t("maths_and_physics.questions.employed_as_supply_teacher"))
    choose "Yes"
    click_on "Continue"
    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

    expect(page).to have_text(I18n.t("maths_and_physics.questions.has_entire_term_contract"))
    choose "Yes"
    click_on "Continue"
    expect(claim.eligibility.reload.has_entire_term_contract).to eql true

    expect(page).to have_text(I18n.t("maths_and_physics.questions.employed_directly"))
    choose "Yes, I’m employed by my school"
    click_on "Continue"
    expect(claim.eligibility.reload.employed_directly).to eql true

    expect(page).to have_text(I18n.t("maths_and_physics.questions.disciplinary_action"))
  end

  scenario "A teacher is ineligible for Maths & Physics" do
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You’re not eligible for this payment")
    expect(page).to have_text("You can only get this payment if you teach maths or physics")
  end
end
