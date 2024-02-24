require "rails_helper"

RSpec.feature "Levelling up premium payments claims" do
  let(:claim) { Claim.by_policy(LevellingUpPremiumPayments).order(:created_at).last }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }
  let!(:school) { create(:school, :levelling_up_premium_payments_eligible) }
  let(:itt_subject) { "Mathematics" }

  def check_eligibility_up_to_apply(expect_to_fail: false)
    start_levelling_up_premium_payments_claim

    check_eligibility_up_to_itt_subject

    select_itt_subject_and_degree

    check_eligibility_after_itt_subject unless expect_to_fail
  end

  def select_itt_subject_and_degree
    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")

    raise "`itt_subject` must be defined" unless defined?(itt_subject)

    choose itt_subject
    click_on "Continue"

    if itt_subject == "None of the above"
      raise "`eligible_degree?` must be defined" unless defined?(eligible_degree?)

      # - Do you have an undergraduate or postgraduate degree in an eligible subject?
      expect(page).to have_text(I18n.t("additional_payments.questions.eligible_degree_subject"))
      choose eligible_degree?
      click_on "Continue"
    end
  end

  def display_ineligibility_message
    expect(page).to have_text("You are not eligible")
  end

  def check_eligibility_up_to_itt_subject
    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "No"
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

    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"

    # - In which academic year did you complete your undergraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2018 to 2019"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")
  end

  def check_eligibility_after_itt_subject
    # - Do you spend at least half of your contracted hours teaching eligible subjects?
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    if itt_subject == "None of the above"
      expect(page).to have_text(I18n.t("additional_payments.questions.eligible_degree_subject"))
    end

    ["Identity details", "Payment details", "Student loan details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_text("levelling up premium payment of:\n£2,000")

    click_on("Apply now")
  end

  def claim_up_to_check_your_answers
    check_eligibility_up_to_apply

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("For more details, you can read about payments and deductions for the levelling up premium payment")
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
    expect(page).to have_link(href: claim_path(Policies::EarlyCareerPayments.routing_name, "address"))

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

    # - Payment to Bank or Building Society
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

    # - Are you currently paying off your student loan
    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.has_student_loan).to eql true

    # - When you applied for your student loan where was your address
    expect(page).to have_text(I18n.t("questions.student_loan_country"))

    choose "England"
    click_on "Continue"

    expect(claim.reload.student_loan_country).to eql("england")

    # - How many higher education courses did you take a student loan out for
    expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

    choose "1"
    click_on "Continue"

    expect(claim.reload.student_loan_courses).to eql("one_course")

    # - When did the first year of your higher education course start
    expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
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

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    within(".govuk-summary-list:nth-of-type(3)") do
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end
  end

  def submit_application
    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("You applied for a levelling up premium payment")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder to apply next year")
    expect(page).to have_text("Apply for additional payment each academic year")
    expect(page).to have_text("What do you think of this service?")
    expect(page).to have_text(claim.reference)

    policy_options_provided = [
      {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
    ]

    expect(claim.reload.policy_options_provided).to eq policy_options_provided
  end

  shared_examples "submittable claim" do
    scenario "user can submit an application" do
      claim_up_to_check_your_answers
      submit_application
    end
  end

  shared_examples "ineligible claim" do
    scenario "user cannot progress the application" do
      check_eligibility_up_to_apply(expect_to_fail: true)
      display_ineligibility_message
    end
  end

  context "when subject 'None of the above'" do
    let(:itt_subject) { "None of the above" }

    context "with an eligible degree" do
      let(:eligible_degree?) { "Yes" }

      it_behaves_like "submittable claim"
    end

    context "without an eligible degree" do
      let(:eligible_degree?) { "No" }

      it_behaves_like "ineligible claim"
    end
  end

  context "when subject 'Computing'" do
    let(:itt_subject) { "Computing" }

    it_behaves_like "submittable claim"
  end

  context "when updating personal details fields" do
    let(:old_last_name) { claim.reload.surname }
    let(:new_last_name) { "#{old_last_name}-McRandom" }

    before do
      claim_up_to_check_your_answers

      first("a[href='#{claim_path(LevellingUpPremiumPayments.routing_name, "personal-details")}']", minimum: 1).click
      fill_in "Last name", with: new_last_name
    end

    scenario "user is then redirected to check your answers" do
      expect { click_on "Continue" }
        .to change { claim.reload.surname }
        .from(old_last_name).to(new_last_name)

      expect(page).to have_content("Check your answers before sending your application")
    end
  end
end
