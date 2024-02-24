require "rails_helper"

RSpec.feature "Combined journey with Teacher ID" do
  include OmniauthMockHelper

  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:eligible_itt_years) { JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(journey_configuration.current_academic_year) }
  let(:academic_date) { Date.new(eligible_itt_years.first.start_year, 12, 1) }
  let(:itt_year) { AcademicYear.for(academic_date) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:eligible_dqt_body) do
    {
      qualified_teacher_status: {
        qts_date: academic_date.to_s
      }
    }
  end

  before do
    allow(NotifySmsMessage).to receive(:new).with(
      phone_number: "07123456789",
      template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
      personalisation: {
        otp: "097543"
      }
    ).and_return(notify)
    allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator",
      code: "097543"))
    allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator",
      valid?: true))
  end

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with Teacher ID and there is a matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{Policies::EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    claim = Claim.all.order(created_at: :desc).limit(1).first
    expect(claim.reload.errors).to be_empty

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))

    choose_school school

    click_on "Continue"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Have you completed your induction as an early-career teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # - Performance Issues
    expect(page).to have_text(I18n.t("early_career_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"

    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    expect(page).to have_text(I18n.t("questions.academic_year.undergraduate_itt"))
    choose "Yes"
    click_on "Continue"

    # Claim eligibility answers are pre-filled from DQT record
    claim.eligibility.reload
    expect(claim.eligibility.eligible_itt_subject).to eq("mathematics")
    expect(claim.eligibility.itt_academic_year).to eq(itt_year)
    expect(claim.eligibility.qualification).to eq("undergraduate_itt")

    # Qualification pages are skipped

    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    ["Identity details", "Payment details", "Student loan details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    within(".govuk-summary-list") do
      expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end

    # Check your answers page does not include qualifications questions
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.qualification.heading"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: "undergraduate initial teacher training (ITT)"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))

    # Go back to the qualification details page
    click_link "Back"

    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
    click_link "Back"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "No"
    click_on "Continue"

    # Claim eligibility answers are wiped
    claim.eligibility.reload
    expect(claim.eligibility.eligible_itt_subject).to be nil
    expect(claim.eligibility.itt_academic_year).to be nil
    expect(claim.eligibility.qualification).to be nil

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
    expect(page).to have_text("2018 to 2019")
    expect(page).to have_text("2019 to 2020")
    expect(page).to have_text("2020 to 2021")
    expect(page).to have_text("2021 to 2022")

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))

    # Check your answers page includes qualifications questions
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject_one_option", qualification: "undergraduate initial teacher training (ITT)", subject: "mathematics"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_field("£2,000 levelling up premium payment")
    expect(page).to have_selector('input[type="radio"]', count: 2)

    choose("£2,000 levelling up premium payment")

    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as TID data all provided for
    expect(page).not_to have_text(I18n.t("questions.personal_details"))

    expect(claim.reload.first_name).to eql("Kelsie")
    expect(claim.reload.surname).to eql("Oberbrunner")
    expect(claim.reload.date_of_birth).to eq(Date.parse(date_of_birth))
    expect(claim.reload.national_insurance_number).to eq(nino)

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
    expect(page).to have_text(I18n.t("questions.select_email.heading"))

    claim = Claim.all.order(created_at: :desc).limit(1).first
    choose claim.teacher_id_user_info["email"]

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.select_phone_number.heading"))

    # - Select the suggested phone number
    choose "01234567890"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))
    choose "Personal bank account"
    click_on "Continue"

    expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

    expect(page).to have_text(I18n.t("questions.account_details",
      bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Sam Harris"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Sam Harris")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Male"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("male")

    # - teacher-reference-number slug removed from user journey
    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    click_link "Back"

    expect(page).to have_text(I18n.t("questions.payroll_gender"))
  end

  scenario "When user is logged in with Teacher ID and there is no matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    click_on "Start now"

    click_on "Continue with DfE Identity"

    choose "Yes"
    click_on "Continue"

    choose_school school

    choose "Yes"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"

    click_on "Continue"

    # Qualification pages are not skipped
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.check_and_confirm_qualification_details"))

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # Check your answers page includes qualifications questions
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject_one_option", qualification: "undergraduate initial teacher training (ITT)", subject: "mathematics"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
  end

  scenario "When user is logged in with Teacher ID and NINO is not supplied" do
    set_mock_auth("1234567", {nino: "", date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino: ""}, body: eligible_dqt_body)

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"
    choose_school school
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "No"
    click_on "Continue"
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped

    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"
    click_on "Continue"

    choose "£2,000 levelling up premium payment"
    click_on "Apply now"
    click_on "Continue"

    # - Personal details
    expect(page).to have_text(I18n.t("questions.personal_details"))

    # - not shown
    expect(page).not_to have_text(I18n.t("questions.name"))
    expect(page).not_to have_text(I18n.t("questions.date_of_birth"))

    # - shown
    expect(page).to have_text(I18n.t("questions.national_insurance_number"))

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    claim = Claim.all.order(created_at: :desc).limit(1).first
    expect(claim.errors).to be_empty
  end

  scenario "When user is logged in with Teacher ID and the qualifications are not eligible" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:})

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"
    choose_school school
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "No"
    click_on "Continue"
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    expect(page).to have_text("You are not eligible for the early-career payment or the levelling up premium payment because of the subject you studied or the year you studied.")
  end

  scenario "When user is logged in with Teacher ID and the qualifications data is incomplete" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    missing_qts_date_body = {
      qualified_teacher_status: {
        qts_date: nil
      }
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"
    choose_school school
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "No"
    click_on "Continue"
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))

    # ITT year is not shown as it is blank
    expect(page).not_to have_text(I18n.t("questions.academic_year.undergraduate_itt"))
    choose "Yes"
    click_on "Continue"

    # Asks user for the missing information
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2020 to 2021"
    click_on "Continue"

    # Skips subject question as supplied by DQT

    # - Do you teach subject now?
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))

    # Check your answers page only includes missing qualifications questions
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.qualification.heading"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: "undergraduate initial teacher training (ITT)"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
  end

  scenario "When user is logged in with Teacher ID and the ITT subject is ineligible" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    missing_qts_date_body = {
      initial_teacher_training: {
        subject1: "philosophy",
        subject1_code: "TEST"
      },
      qualifications: [
        {
          he_subject1: "mathematics"
        }
      ]
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"
    choose_school school
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "No"
    click_on "Continue"
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # Degree subject is shown because the ITT is ineligible
    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    expect(page).to have_text(I18n.t("questions.itt_subject.undergraduate_itt"))
    expect(page).to have_text("Philosophy")
    expect(page).to have_text(I18n.t("questions.degree_subject"))
    expect(page).to have_text("Mathematics")
  end
end
