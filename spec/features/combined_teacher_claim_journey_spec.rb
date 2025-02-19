require "rails_helper"

RSpec.feature "Levelling up premium payments and early-career payments combined claim journey", :with_stubbed_hmrc_client, :with_hmrc_bank_validation_enabled do
  let(:journey_session) do
    Journeys::AdditionalPaymentsForTeaching::Session.order(:created_at).last
  end
  let(:eligibility) { claim.eligibility }

  scenario "Eligible for both" do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023))

    school = create(:school, :combined_journey_eligibile_for_all)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # Check we can't skip ahead pages in the journey
    visit claim_confirmation_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/landing-page")

    click_on "Start now"
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/existing-session")

    choose "Start a new eligibility check"
    click_on "Continue"

    skip_tid

    # Check we can't skip ahead pages in the journey
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "nqt-in-academic-year-after-itt")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/current-school")

    # Check we can't skip ahead pages in the journey
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "qualification")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/current-school")

    # - Which school do you teach at
    journey_session.answers.assign_attributes(details_check: true)
    journey_session.save!
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
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.question"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

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
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
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
    expect(page).to have_field("£2,000 school targeted retention incentive")
    expect(page).to have_selector('input[type="radio"]', count: 2)

    choose("£2,000 school targeted retention incentive")

    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details
    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text(I18n.t("questions.name"))

    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"

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
    expect(page).to have_text(I18n.t("forms.address.questions.your_address"))

    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
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
    fill_in "claim-one-time-password-field", with: "000000"
    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")

    # - clear and enter correct OTP
    fill_in "claim-one-time-password-field-error", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    choose "No"
    click_on "Continue"

    # - Mobile number
    expect(page).not_to have_text(I18n.t("questions.mobile_number"))

    # - Mobile number one-time password
    expect(page).not_to have_text("Enter the 6-digit passcode")

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: "personal bank account"))

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"

    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("forms.teacher_reference_number.questions.teacher_reference_number"))

    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    click_on "Accept and send"

    submitted_claim = Claim.by_policy(Policies::TargetedRetentionIncentivePayments).order(:created_at).last
    # - Application complete
    expect(page).to have_text("You applied for a school targeted retention incentive")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder to apply next year")
    expect(page).to have_text("Apply for additional payment each academic year")
    expect(page).to have_text("What do you think of this service?")
    expect(page).to have_text(submitted_claim.reference)

    policy_options_provided = [
      {"policy" => "EarlyCareerPayments", "award_amount" => "2000.0"},
      {"policy" => "TargetedRetentionIncentivePayments", "award_amount" => "2000.0"}
    ]

    expect(submitted_claim.policy_options_provided).to eq policy_options_provided

    # Check we can't skip to pages in middle of page sequence after claim is submitted
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "qualification")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/landing-page")
  end

  scenario "Eligible for only one" do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023))

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
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.question"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

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
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
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

  context "when ECP is closed" do
    before do
      create(
        :journey_configuration,
        :additional_payments,
        current_academic_year: AcademicYear.new(2025)
      )
    end

    scenario "choosing an ecp only school is ineligible" do
      school = create(:school, :early_career_payments_eligible)

      visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

      click_on "Continue without signing"

      choose_school school

      expect(page).to have_content "You are not eligible"
      expect(page).to have_content "the policy has now closed"
    end

    scenario "choosing a Targeted Retention Incentive eligible school allows completing the journey" do
      school = create(:school, :combined_journey_eligibile_for_all)

      visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

      click_on "Continue without signing"

      choose_school school
      click_on "Continue"

      # - Have you started your first year as a newly qualified teacher?
      choose "Yes"
      click_on "Continue"

      # - Have you completed your induction as an early-career teacher?
      choose "Yes"
      click_on "Continue"

      # - Are you currently employed as a supply teacher
      choose "No"
      click_on "Continue"

      # - Poor performance
      within all(".govuk-fieldset")[0] do
        choose("No")
      end
      within all(".govuk-fieldset")[1] do
        choose("No")
      end
      click_on "Continue"

      # - What route into teaching did you take?
      choose("Undergraduate initial teacher training (ITT)")
      click_on "Continue"

      # - In which academic year did you complete your undergraduate ITT?
      choose("2024 to 2025")
      click_on "Continue"

      # - Which subject did you do your undergraduate ITT in
      choose "Mathematics"
      click_on "Continue"

      # Do you spend at least half of your contracted hours teaching eligible
      # subjects?
      choose "Yes"
      click_on "Continue"

      # Check your answers
      click_on "Continue"

      expect(page).to have_content("You’re eligible for an additional payment")
      expect(page).to have_content(
        "you can apply for a school targeted retention incentive"
      )
    end
  end
end
