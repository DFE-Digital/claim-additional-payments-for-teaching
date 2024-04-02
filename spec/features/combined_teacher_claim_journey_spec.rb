require "rails_helper"

RSpec.feature "Levelling up premium payments and early-career payments combined claim journey", :with_stubbed_hmrc_client, :with_hmrc_bank_validation_enabled do
  let(:claim) { Claim.by_policy(Policies::LevellingUpPremiumPayments).order(:created_at).last }
  let(:eligibility) { claim.eligibility }

  before { create(:journey_configuration, :additional_payments) }

  scenario "Eligible for both" do
    school = create(:school, :combined_journey_eligibile_for_all)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # Check we can't skip ahead pages in the journey
    visit claim_completion_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/landing-page")

    click_on "Start now"
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/existing-session")

    choose "Yes, start claim for an additional payment for teaching and lose my progress on my first claim"
    click_on "Submit"

    skip_tid

    # Check we can't skip ahead pages in the journey
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "nqt-in-academic-year-after-itt")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/current-school")

    # Check we can't skip ahead pages in the journey
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "qualification")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/current-school")

    # - Which school do you teach at
    claim.update(details_check: true)
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

    choose "Postgraduate initial teacher training (ITT)"

    click_on "Continue"

    # - In which academic year did you complete your postgraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.postgraduate_itt"))

    choose "2020 to 2021"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    ["Identity details", "Payment details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_field("£2,000 early-career payment")
    expect(page).to have_field("£2,000 levelling up premium payment")
    expect(page).to have_selector('input[type="radio"]', count: 2)

    choose("£2,000 levelling up premium payment")

    click_on("Apply now")

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

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "address"))

    # Check we can't skip to pages if address not entered
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "email-address")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/address")

    click_on "Back"

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    expect(page).to have_text(I18n.t("questions.address.generic.title"))

    fill_in :claim_address_line_1, with: "57"
    fill_in :claim_address_line_2, with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    # - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

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

    # - Mobile number
    expect(page).not_to have_text(I18n.t("questions.mobile_number"))

    # - Mobile number one-time password
    expect(page).not_to have_text("Enter the 6-digit passcode")

    # Payment to Bank or Building Society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    choose "Personal bank account"
    click_on "Continue"

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.reload.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"

    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    click_on "Accept and send"

    # - Application complete
    expect(page).to have_text("You applied for a levelling up premium payment")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder to apply next year")
    expect(page).to have_text("Apply for additional payment each academic year")
    expect(page).to have_text("What do you think of this service?")
    expect(page).to have_text(claim.reload.reference)

    policy_options_provided = [
      {"policy" => "EarlyCareerPayments", "award_amount" => "2000.0"},
      {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
    ]

    expect(claim.reload.policy_options_provided).to eq policy_options_provided

    # Check we can't skip to pages in middle of page sequence after claim is submitted
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "qualification")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/landing-page")
  end

  scenario "Eligible for only one" do
    school = create(:school, :early_career_payments_uplifted)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

    choose "Postgraduate initial teacher training (ITT)"

    click_on "Continue"

    # - In which academic year did you complete your postgraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.postgraduate_itt"))

    choose "2020 to 2021"
    click_on "Continue"

    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    ["Identity details", "Payment details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    expect(page).to have_text("Based on what you told us, you can apply for an early-career payment of:\n£3,000")
    expect(page).not_to have_selector('input[type="radio"]')
    expect(page).to have_button("Apply now")
  end
end
