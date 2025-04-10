require "rails_helper"

RSpec.feature "targeted_retention_incentive payments claims" do
  let(:claim) { Claim.by_policy(Policies::TargetedRetentionIncentivePayments).order(:created_at).last }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }
  let!(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
  let(:itt_subject) { "Mathematics" }
  let(:journey_session) do
    Journeys::AdditionalPaymentsForTeaching::Session.order(:created_at).last
  end

  def check_eligibility_up_to_apply(expect_to_fail: false)
    start_targeted_retention_incentive_payments_claim

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
      expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
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
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

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
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    if itt_subject == "None of the above"
      expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
    end

    ["Identity details", "Payment details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    click_on("Continue")

    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_text("school targeted retention incentive of:\n£2,000")

    click_on("Apply now")
  end

  def claim_up_to_check_your_answers
    check_eligibility_up_to_apply

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("For more details, you can read about payments and deductions for the school targeted retention incentive")
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
    otp_in_mail_sent = mail.personalisation[:one_time_password]

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
    expect(page).not_to have_text("Building society roll number")

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
  end

  def submit_application
    freeze_time do
      click_on "Accept and send"

      expect(Claim.count).to eq 1

      submitted_claim = Claim.by_policy(Policies::TargetedRetentionIncentivePayments).order(:created_at).last

      expect(submitted_claim.submitted_at).to eq(Time.zone.now)
      expect(submitted_claim.first_name).to eql("Russell")
      expect(submitted_claim.surname).to eql("Wong")
      expect(submitted_claim.date_of_birth).to eq(Date.new(1988, 2, 28))
      expect(submitted_claim.national_insurance_number).to eq("PX321499A")
      expect(submitted_claim.address_line_1).to eql("57")
      expect(submitted_claim.address_line_2).to eql("Walthamstow Drive")
      expect(submitted_claim.address_line_3).to eql("Derby")
      expect(submitted_claim.address_line_4).to eql("City of Derby")
      expect(submitted_claim.postcode).to eql("DE22 4BS")
      expect(submitted_claim.email_address).to eql("david.tau1988@hotmail.co.uk")
      expect(submitted_claim.provide_mobile_number).to eql false
      expect(submitted_claim.banking_name).to eq("Jo Bloggs")
      expect(submitted_claim.bank_sort_code).to eq("123456")
      expect(submitted_claim.bank_account_number).to eq("87654321")
      expect(submitted_claim.payroll_gender).to eq("female")
      expect(submitted_claim.eligibility.teacher_reference_number).to eql("1234567")

      # - Application complete (make sure its Word for Word and styling matches)
      expect(page).to have_text("You applied for a school targeted retention incentive")
      expect(page).to have_text("What happens next")
      expect(page).to have_text("Set a reminder to apply next year")
      expect(page).to have_text("Apply for additional payment each academic year")
      expect(page).to have_text("What do you think of this service?")
      expect(page).to have_text(submitted_claim.reference)

      policy_options_provided = [
        {"policy" => "TargetedRetentionIncentivePayments", "award_amount" => "2000.0"}
      ]

      expect(submitted_claim.policy_options_provided).to eq policy_options_provided
    end
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
    let(:old_last_name) { journey_session.reload.answers.surname }
    let(:new_last_name) { "#{old_last_name}-McRandom" }

    before do
      claim_up_to_check_your_answers

      click_link "Change what is your full name?"
      fill_in "Last name", with: new_last_name
    end

    scenario "user is then redirected to check your answers" do
      expect { click_on "Continue" }
        .to change { journey_session.reload.answers.surname }
        .from(old_last_name).to(new_last_name)

      expect(page).to have_content("Check your answers before sending your application")
    end
  end
end
