require "rails_helper"

RSpec.feature "Maths & Physics claims" do
  [true, false].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims for Maths & Physics payment with JavaScript #{js_status}", js: javascript_enabled do
      visit new_claim_path(MathsAndPhysics.routing_name)
      expect(page).to have_link(href: "mailto:#{MathsAndPhysics.feedback_email}")

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

      # - Personal details
      expect(page).to have_text(I18n.t("questions.personal_details"))
      expect(page).to have_text(I18n.t("questions.name"))

      fill_in "claim_first_name", with: "Russell"
      fill_in "claim_surname", with: "Wong"

      expect(page).to have_text(I18n.t("questions.date_of_birth"))

      fill_in "Day", with: "28"
      fill_in "Month", with: "2"
      fill_in "Year", with: "1988"

      expect(page).to have_text(I18n.t("questions.national_insurance_number"))

      fill_in "National Insurance number", with: "PX321499A"
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Russell")
      expect(claim.reload.surname).to eql("Wong")
      expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
      expect(claim.reload.national_insurance_number).to eq("PX321499A")

      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(MathsAndPhysics.routing_name, "address"))

      click_link(I18n.t("questions.address.home.link_to_manual_address"))

      expect(page).to have_text(I18n.t("questions.address.generic.title"))
      fill_in_address

      expect(claim.reload.address_line_1).to eql("123 Main Street")
      expect(claim.address_line_2).to eql("Downtown")
      expect(claim.address_line_3).to eql("Twin Peaks")
      expect(claim.address_line_4).to eql("Washington")
      expect(claim.postcode).to eql("M1 7HL")

      expect(page).to have_text(I18n.t("questions.payroll_gender"))
      choose "Female"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("female")

      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))
      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      answer_student_loan_plan_questions

      expect(claim.reload).to have_student_loan
      expect(claim.student_loan_country).to eq("england")
      expect(claim.student_loan_courses).to eq("one_course")
      expect(claim.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      # - Are you currently paying off your masters/doctoral loan
      expect(page).not_to have_text(I18n.t("questions.has_masters_and_or_doctoral_loan"))
      expect(claim.reload.has_masters_doctoral_loan).to be_nil

      # - Did you take out a postgraduate masters loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_masters_loan).to eql true

      # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_doctoral_loan).to eql true

      expect(page).to have_text(I18n.t("questions.email_address"))
      expect(page).to have_text(I18n.t("questions.email_address_hint1"))
      fill_in I18n.t("questions.email_address"), with: "name@example.com"
      click_on "Continue"

      expect(claim.reload.email_address).to eq("name@example.com")

      # - One time password
      expect(page).to have_text("Enter the 6-digit password")

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail.body.decoded.scan(/\b[0-9]{6}\b/).first

      fill_in "claim_one_time_password", with: otp_in_mail_sent

      click_on "Confirm"

      # - Provide mobile number
      expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.provide_mobile_number).to eql true

      # - Mobile number
      expect(page).to have_text(I18n.t("questions.mobile_number"))

      fill_in "claim_mobile_number", with: "07123456789"
      click_on "Continue"

      expect(claim.reload.mobile_number).to eql("07123456789")

      # - Mobile number one-time password
      # expect(page).to have_text("Password verification")
      # expect(page).to have_text("Enter the 6-digit password")
      # expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

      # fill_in "claim_one_time_password", with: otp_sent_to_mobile
      # click_on "Confirm"

      expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

      choose "Building society"
      click_on "Continue"

      expect(claim.reload.bank_or_building_society).to eq "building_society"

      expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
      expect(page).to have_text("Building society roll number")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      fill_in "Building society roll number", with: "1234/123456789"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.bank_sort_code).to eq("123456")
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
