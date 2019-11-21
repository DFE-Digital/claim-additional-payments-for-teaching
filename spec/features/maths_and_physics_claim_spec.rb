require "rails_helper"

RSpec.feature "Maths & Physics claims" do
  [true, false].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims for Maths & Physics payment with JavaScript #{js_status}", js: javascript_enabled do
      visit "maths-and-physics/start"
      expect(page).to have_text "Claim a payment for teaching maths or physics"

      click_on "Start"
      expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

      choose "Yes"
      click_on "Continue"

      claim = Claim.order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.teaching_maths_or_physics).to eql true

      expect(page).to have_text(I18n.t("questions.current_school"))
      choose_school schools(:penistone_grammar_school)
      expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

      expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"))
      choose "Yes"
      click_on "Continue"
      expect(claim.eligibility.reload.initial_teacher_training_specialised_in_maths_or_physics).to eql true

      expect(page).to have_text(I18n.t("questions.qts_award_year"))
      choose_qts_year "On or after 1 September 2014"
      expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_september_2014")

      expect(page).to have_text("You are eligible to claim a payment for teaching maths or physics")

      click_on "Continue"

      expect(page).to have_text("How we will use the information you provide")
      perform_verify_step
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Isambard")
      expect(claim.reload.middle_name).to eql("Kingdom")
      expect(claim.reload.surname).to eql("Brunel")
      expect(claim.address_line_1).to eq("Verified Building")
      expect(claim.address_line_2).to eq("Verified Street")
      expect(claim.address_line_3).to eq("Verified Town")
      expect(claim.address_line_4).to eq("Verified County")
      expect(claim.postcode).to eql("M12 345")
      expect(claim.date_of_birth).to eq(Date.new(1806, 4, 9))
      expect(claim.payroll_gender).to eq("male")

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
    end
  end

  scenario "Teacher claims for Maths and Physics, without maths or physics ITT and with a UK degree in maths or physics" do
    # This test was initially written for the purpose of building out this
    # alternative journey. It does not test the whole claims journey but only
    # this part of it. Not sure of the best approach.
    visit "maths-and-physics/start"
    expect(page).to have_text "Claim a payment for teaching maths or physics"

    click_on "Start"
    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.teaching_maths_or_physics).to eql true

    expect(page).to have_text(I18n.t("questions.current_school"))
    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"))
    choose "No"
    click_on "Continue"
    expect(claim.eligibility.reload.initial_teacher_training_specialised_in_maths_or_physics).to eql false

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
    visit "maths-and-physics/start"
    expect(page).to have_text "Claim a payment for teaching maths or physics"

    click_on "Start"
    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.teaching_maths_or_physics).to eql true

    expect(page).to have_text(I18n.t("questions.current_school"))
    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"))
    choose "No"
    click_on "Continue"
    expect(claim.eligibility.reload.initial_teacher_training_specialised_in_maths_or_physics).to eql false

    expect(page).to have_text(I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"))
    choose "I have a non-UK degree in Maths or Physics"
    click_on "Continue"
    expect(claim.eligibility.reload.has_uk_maths_or_physics_degree).to eql "has_non_uk"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
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
