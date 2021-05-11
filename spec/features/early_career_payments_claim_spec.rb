require "rails_helper"

RSpec.feature "Teacher Early Career Payments claims" do
  scenario "Teacher makes claim for 'Early Career Payments' claim" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # [PAGE 00] - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # TODO [PAGE 02] - Which school do you teach at
    # TODO [PAGE 03] - Select the school you teach at
    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # [PAGE 07] - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false

    # [PAGE 08] - Are you currently subject to dsiciplinary action
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # [PAGE 09] - Did you do a postgraduate ITT course or undergraduate ITT course
    expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_itt_or_undergraduate_itt_course"))

    choose "Postgraduate"
    click_on "Continue"

    expect(claim.eligibility.reload.pgitt_or_ugitt_course).to eq "postgraduate"

    # [PAGE 10] - ITT Subject
    # - Which subject did you do your undergraduate ITT in
    #   - OR -
    # - Which subject did you do your postgraduate ITT in

    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", ug_or_pg: claim.eligibility.reload.pgitt_or_ugitt_course))

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # [PAGE 12] - Do you teach maths now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    # [PAGE 13] - ITT Academic Year
    # In what academic year did you start your undergraduate ITT
    # - OR -
    # In what academic year did you start your postgraduate ITT

    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year", start_or_complete: "start", ug_or_pg: claim.eligibility.pgitt_or_ugitt_course))

    choose "2018 - 2019"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"

    # [PAGE 15] - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    within(".govuk-summary-list") do
      expect(page).not_to have_text(I18n.t("early_career_payments.questions.postgraduate_masters_loan"))
      expect(page).not_to have_text(I18n.t("early_career_payments.questions.postgraduate_doctoral_loan"))
    end

    click_on("Continue")

    # [PAGE 16] - You are eligible for an early career payment
    expect(page).to have_text("You are eligible " + I18n.t("early_career_payments.claim_description"))
    within(".govuk-list--bullet") do
      expect(page).to have_text("your National Insurance number")
      ["bank account details", "teacher reference number", "QTS certificate", "student loan"].each do |bullet_point|
        expect(page).to have_text bullet_point
      end
    end

    click_on "Continue"

    # [PAGE 23] - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")

    click_on "Continue"

    # [PAGE 24] - Personal details
    expect(page).to have_text(I18n.t("early_career_payments.personal_details"))
    expect(page).to have_text(I18n.t("questions.name"))

    fill_in "claim_first_name", with: "Russell"
    fill_in "claim_surname", with: "Wong"

    expect(page).to have_text(I18n.t("questions.date_of_birth"))

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"

    expect(page).to have_text(I18n.t("early_career_payments.questions.national_insurance_number"))

    fill_in "National Insurance number", with: "PX321499A"

    click_on "Continue"

    expect(claim.reload.first_name).to eql("Russell")
    expect(claim.reload.surname).to eql("Wong")
    expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
    expect(claim.reload.national_insurance_number).to eq("PX321499A")

    # [PAGE 25] - What is your address
    expect(page).to have_text(I18n.t("questions.address"))

    fill_in_address

    expect(claim.reload.address_line_1).to eql("123 Main Street")
    expect(claim.address_line_2).to eql("Downtown")
    expect(claim.address_line_3).to eql("Twin Peaks")
    expect(claim.address_line_4).to eql("Washington")
    expect(claim.postcode).to eql("M1 7HL")

    # [PAGE 26] - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"

    click_on "Continue"

    expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

    # [PAGE 27] - Enter bank account details
    expect(page).to have_text(I18n.t("questions.bank_details"))

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    fill_in "Building society roll number (if you have one)", with: "1234/123456789"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Jo Bloggs")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")
    expect(claim.building_society_roll_number).to eq("1234/123456789")

    # [PAGE 28] - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    # [PAGE 29] - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    # [PAGE 30] - Are you currently paying off your student loan
    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.has_student_loan).to eql true

    # [PAGE 31] - When you applied for your student loan where was your address
    expect(page).to have_text(I18n.t("questions.student_loan_country"))

    choose "England"
    click_on "Continue"

    expect(claim.reload.student_loan_country).to eql("england")
    # [PAGE 32] - How many higher education courses did you take a student loan out for
    expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

    choose "1"
    click_on "Continue"

    expect(claim.reload.student_loan_courses).to eql("one_course")
    # [PAGE 33] - When did the first year of your higher education course start
    expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
    expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

    # [PAGE 35] - Did you take out a postgraduate masters loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_masters_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.postgraduate_masters_loan).to eql true

    # [PAGE 36] - Did you take out a postgraduate doctoral loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_doctoral_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.postgraduate_doctoral_loan).to eql true

    # TODO [PAGE 37] - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    within(".govuk-summary-list:nth-of-type(3)") do
      expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_masters_loan"))
      expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_doctoral_loan"))
    end

    stub_geckoboard_dataset_update

    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # [PAGE 38] - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("Application complete")
    expect(page).to have_text(claim.reference)
  end

  # As part of Eligible Later Process
  # TODO [PAGE 20] - Personal Details
  # TODO [PAGE 21] - One Time Password
  # TODO [PAGE 22] - We have sent you reminders

  scenario "Supply Teacher makes claim for 'Early Career Payments' with a contract to teach for entire term & employed directly by school" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # [PAGE 00] - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # TODO [PAGE 02] - Which school do you teach at
    # TODO [PAGE 03] - Select the school you teach at
    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

    # [PAGE 05] - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.has_entire_term_contract).to eql true

    # [PAGE 06] - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "Yes, I'm employed by my school"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_directly).to eql true

    # [PAGE 07] - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))

    choose "No"
    click_on "Continue"
  end
end
