require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims", slow: true do
  include AdditionalPaymentsHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { journey_configuration.current_academic_year }

  let(:itt_year) { current_academic_year - 3 }

  scenario "Teacher makes claim for 'Early-Career Payments' claim" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.by_policy(Policies::EarlyCareerPayments).order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # - Performance Issues
    expect(page).to have_text(I18n.t("additional_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"

    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
    expect(page).to have_text("2017 to 2018")
    expect(page).to have_text("2018 to 2019")
    expect(page).to have_text("2019 to 2020")
    expect(page).to have_text("2020 to 2021")
    expect(page).to have_text("2021 to 2022")

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    expect(claim.eligibility.reload.itt_academic_year).to eql itt_year

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))
    expect(page).not_to have_text(I18n.t("additional_payments.questions.eligible_degree_subject"))

    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_text("£5,000 early-career payment")

    choose "£5,000 early-career payment"
    click_on "Apply now"

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("For more details, you can read about payments and deductions for the early-career payment")
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

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "address"))

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    expect(page).to have_text(I18n.t("questions.address.generic.title"))

    fill_in :claim_address_line_1, with: "57"
    fill_in :claim_address_line_2, with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("57")
    expect(claim.address_line_2).to eql("Walthamstow Drive")
    expect(claim.address_line_3).to eql("Derby")
    expect(claim.address_line_4).to eql("City of Derby")
    expect(claim.postcode).to eql("DE22 4BS")

    # - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

    expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

    # - One time password
    expect(page).to have_text("Email address verification")
    expect(page).to have_text("Enter the 6-digit passcode")

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

    # - One time password wrong
    fill_in "claim_one_time_password", with: "000000"
    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")

    # - clear and enter correct OTP
    fill_in "claim_one_time_password", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    choose "No"
    click_on "Continue"

    expect(claim.reload.provide_mobile_number).to eql false

    # - Mobile number
    expect(page).not_to have_text(I18n.t("questions.mobile_number"))

    # - Mobile number one-time password
    expect(page).not_to have_text("Enter the 6-digit passcode")

    # Payment to Bank or Building Society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    choose "Personal bank account"
    click_on "Continue"

    expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Jo Bloggs")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("You applied for an early-career payment")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder to apply next year")
    expect(page).to have_text("Apply for additional payment each academic year")
    expect(page).to have_text("What do you think of this service?")
    expect(page).to have_text(claim.reference)

    policy_options_provided = [
      {"policy" => "EarlyCareerPayments", "award_amount" => "5000.0"},
      {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
    ]

    expect(claim.reload.policy_options_provided).to eq policy_options_provided
  end

  scenario "Supply Teacher makes claim for 'Early Career Payments' with a contract to teach for entire term & employed directly by school" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.by_policy(Policies::EarlyCareerPayments).order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("additional_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.has_entire_term_contract).to eql true

    # - Are you employed directly by your school
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_directly"))

    choose "Yes, I'm employed by my school"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_directly).to eql true

    # - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
  end

  context "Route into teaching" do
    let!(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.eligibility.update!(current_school: school)
      claim
    end

    let!(:lup_claim) do
      lup_claim = Claim.by_policy(Policies::LevellingUpPremiumPayments).order(:created_at).last
      lup_claim.eligibility.update!(attributes_for(:levelling_up_premium_payments_eligibility, :eligible))
      lup_claim.eligibility.update!(current_school: school)
      lup_claim
    end

    scenario "when Assessment only" do
      jump_to_claim_journey_page(claim, "qualification")

      # - What route into teaching did you take?
      expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

      choose "Assessment only"
      click_on "Continue"

      expect(claim.eligibility.reload.qualification).to eq "assessment_only"

      # - In which academic year did you earn your qualified teacher status (QTS)
      expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
      expect(page).to have_text("2017 to 2018")
      expect(page).to have_text("2018 to 2019")
      expect(page).to have_text("2019 to 2020")
      expect(page).to have_text("2020 to 2021")
      expect(page).to have_text("2021 to 2022")

      choose "#{itt_year.start_year} to #{itt_year.end_year}"
      click_on "Continue"

      expect(page).to have_text("Which subject")

      choose "Mathematics"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

      # - Do you teach maths now
      expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))

      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.teaching_subject_now).to eql true

      click_on "Continue"

      expect(claim.eligibility.reload.itt_academic_year).to eql itt_year
    end

    scenario "when Overseas recognition" do
      jump_to_claim_journey_page(claim, "qualification")

      # - What route into teaching did you take?
      expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

      choose "Overseas recognition"
      click_on "Continue"

      expect(claim.eligibility.reload.qualification).to eq "overseas_recognition"

      # - In which academic year did you you earn your qualified teacher status (QTS)?
      expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
      expect(page).to have_text("2017 to 2018")
      expect(page).to have_text("2018 to 2019")
      expect(page).to have_text("2019 to 2020")
      expect(page).to have_text("2020 to 2021")
      expect(page).to have_text("2021 to 2022")

      choose "#{itt_year.start_year} to #{itt_year.end_year}"
      click_on "Continue"

      expect(page).to have_text("Which subject")

      choose "Mathematics"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

      # - Do you teach maths now
      expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))

      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.teaching_subject_now).to eql true

      expect(claim.eligibility.reload.itt_academic_year).to eql itt_year
    end
  end

  scenario "Teacher makes claim for 'Early Career Payments' without uplift school" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.by_policy(Policies::EarlyCareerPayments).order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # - Performance Issues
    expect(page).to have_text(I18n.t("additional_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

    # - In which academic year did you start your postgraduate ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
    expect(page).to have_text("2017 to 2018")
    expect(page).to have_text("2018 to 2019")
    expect(page).to have_text("2019 to 2020")
    expect(page).to have_text("2020 to 2021")
    expect(page).to have_text("2021 to 2022")

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    expect(claim.eligibility.reload.itt_academic_year).to eql itt_year

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_text("£5,000 early-career payment")

    choose "£5,000 early-career payment"
    click_on "Apply now"

    # - How will we use the information you provide
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

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "address"))

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    expect(page).to have_text(I18n.t("questions.address.generic.title"))

    fill_in :claim_address_line_1, with: "88"
    fill_in :claim_address_line_2, with: "Deanborough Street"
    fill_in "Town or city", with: "Nottingham"
    fill_in "County", with: "Nottinghamshire"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("88")
    expect(claim.address_line_2).to eql("Deanborough Street")
    expect(claim.address_line_3).to eql("Nottingham")
    expect(claim.address_line_4).to eql("Nottinghamshire")
    expect(claim.postcode).to eql("M1 7HL")

    # - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

    expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

    # - One time password
    expect(page).to have_text("Email address verification")
    expect(page).to have_text("Enter the 6-digit passcode")

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

    fill_in "claim_one_time_password", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    choose "No"
    click_on "Continue"

    expect(claim.reload.provide_mobile_number).to eql false

    # - Mobile number
    expect(page).not_to have_text(I18n.t("questions.mobile_number"))

    # - Mobile number one-time password
    expect(page).not_to have_text("Enter the 6-digit passcode")

    # Payment to Bank or Building Society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    choose "Personal bank account"
    click_on "Continue"

    expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Jo Bloggs")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("You applied for an early-career payment")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder to apply next year")
    expect(page).to have_text("What do you think of this service?")
    expect(page).to have_text(claim.reference)

    policy_options_provided = [
      {"policy" => "EarlyCareerPayments", "award_amount" => "5000.0"},
      {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
    ]

    expect(claim.reload.policy_options_provided).to eq policy_options_provided
  end

  context "When auto-populating address details" do
    before do
      body = <<-RESULTS
        {
          "header" : {
            "uri" : "https://api.os.uk/search/places/v1/postcode?postcode=SO169FX",
            "query" : "postcode=SO169FX",
            "offset" : 0,
            "totalresults" : 50,
            "format" : "JSON",
            "dataset" : "DPA",
            "lr" : "EN,CY",
            "maxresults" : 100,
            "epoch" : "85",
            "output_srs" : "EPSG:27700"
          },
          "results" : [
            {
              "DPA" : {
                "UPRN" : "100062039919",
                "UDPRN" : "22785699",
                "ADDRESS" : "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 1",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039928",
                "UDPRN" : "22785700",
                "ADDRESS" : "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 10",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039929",
                "UDPRN" : "22785701",
                "ADDRESS" : "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 11",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            }
          ]
        }
      RESULTS

      stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SO169FX")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "Expect" => "",
            "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
          }
        ).to_return(status: 200, body: body, headers: {})
    end

    let!(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.eligibility.update!(current_school: school)
      claim
    end

    let!(:lup_claim) do
      lup_claim = Claim.by_policy(Policies::LevellingUpPremiumPayments).order(:created_at).last
      lup_claim.eligibility.update!(attributes_for(:levelling_up_premium_payments_eligibility, :eligible))
      lup_claim.eligibility.update!(current_school: school)
      lup_claim
    end

    scenario "with Ordnance Survey data" do
      expect(claim.valid?(:submit)).to eq false
      jump_to_claim_journey_page(claim, "check-your-answers-part-one")

      # - Check your answers for eligibility
      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

      %w[Identity\ details Payment\ details].each do |section_heading|
        expect(page).not_to have_text section_heading
      end

      click_on("Continue")

      # - You are eligible for an early career payment
      expect(page).to have_text("You’re eligible for an additional payment")
      expect(page).to have_text("£5,000 early-career payment")

      choose "£5,000 early-career payment"
      click_on "Apply now"

      # - How will we use the information you provide
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

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "address"))

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))

      choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql "Flat 11, Millbrook Tower"
      expect(claim.address_line_2).to eql "Windermere Avenue"
      expect(claim.address_line_3).to eql "Southampton"
      expect(claim.postcode).to eql "SO16 9FX"

      # - What is your address
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))

      fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
      click_on "Continue"

      expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

      # - One time password
      expect(page).to have_text("Email address verification")
      expect(page).to have_text("Enter the 6-digit passcode")

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

      fill_in "claim_one_time_password", with: otp_in_mail_sent
      click_on "Confirm"

      # - Provide mobile number
      expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

      choose "No"
      click_on "Continue"

      expect(claim.reload.provide_mobile_number).to eql false

      # - Mobile number
      expect(page).not_to have_text(I18n.t("questions.mobile_number"))

      # - Mobile number one-time password
      expect(page).not_to have_text("Enter the 6-digit passcode")

      # Payment to Bank or Building Society
      expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

      choose "Personal bank account"
      click_on "Continue"

      expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

      # - Enter bank account details
      expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
      expect(page).not_to have_text("Building society roll number")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")

      # - What gender does your school's payroll system associate with you
      expect(page).to have_text(I18n.t("questions.payroll_gender"))

      choose "Female"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("female")

      # - What is your teacher reference number
      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      # - Check your answers before sending your application
      expect(page).to have_text("Check your answers before sending your application")
      expect(page).not_to have_text("Eligibility details")
      %w[Identity\ details Payment\ details].each do |section_heading|
        expect(page).to have_text section_heading
      end

      freeze_time do
        click_on "Accept and send"

        expect(claim.reload.submitted_at).to eq(Time.zone.now)
      end

      # - Application complete (make sure its Word for Word and styling matches)
      expect(page).to have_text("You applied for an early-career payment")
      expect(page).to have_text("What happens next")
      expect(page).to have_text("Set a reminder to apply next year")
      expect(page).to have_text("What do you think of this service?")
      expect(page).to have_text(claim.reference)

      policy_options_provided = [
        {"policy" => "EarlyCareerPayments", "award_amount" => "5000.0"},
        {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
      ]

      expect(claim.reload.policy_options_provided).to eq policy_options_provided
    end
  end

  context "ECP school" do
    let!(:school) { create(:school, :early_career_payments_eligible) }

    scenario "Prevent eligible itt subject page loading form from browser Back navigation causing errors", js: true, flaky: true do
      visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
      click_on "Start now"

      skip_tid

      # - Which school do you teach at
      choose_school school

      # - NQT in Academic Year after ITT
      choose "Yes"
      click_on "Continue"

      # - Completed induction as an early-career teacher?
      choose "Yes"
      click_on "Continue"

      # - Are you currently employed as a supply teacher
      choose "No"
      click_on "Continue"

      # - Performance Issues
      # No
      choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
      # "No"
      choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
      click_on "Continue"

      # - What route into teaching did you take?
      choose "Undergraduate initial teacher training (ITT)"
      click_on "Continue"

      # - In which academic year did you start your undergraduate ITT
      choose "2018 to 2019"
      click_on "Continue"

      # - eligible_itt_subject page - Choose Yes/No on Mathematics page only because 2018/2019 was selected
      choose "No"
      click_on "Continue"

      # - Hit ineligible page
      expect(page).to have_text("You are not eligible")

      # Click back on the browser
      page.go_back

      # NOTE: At stage if you click continue you will get "'on' is not a valid eligible_itt_subject" exception
      # - eligible_itt_subject page - Choose Yes
      # page.all(:css, ".govuk-radios__input", visible: :all).select { |n| n.value == "on" }.first.choose
      # click_on "Continue"

      # The bugfix is the form is NOT hidden to prevent it being submitted
      expect(page).not_to have_text("Did you do your undergraduate initial teacher training (ITT) in ?")
      expect(page).not_to have_button("Continue")

      # Should show a blank page with just the "Back" link
      click_on "Back"

      expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    end
  end
end
