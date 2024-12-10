require "rails_helper"

RSpec.feature "Combined journey with Teacher ID" do
  include OmniauthMockHelper

  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }
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
    stub_otp_verification
  end

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with Teacher ID and there is a matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    navigate_until_performance_related_questions

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    expect(page).to have_text(I18n.t("questions.academic_year.undergraduate_itt"))
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped

    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    ["Identity details", "Payment details", "Student loan details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    # Check your answers page does not include qualifications questions
    expect(page).not_to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_itt_subject.questions.which_subject", qualification: "undergraduate initial teacher training (ITT)"))
    expect(page).not_to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))

    # Go back to the qualification details page
    click_link "Back"

    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
    click_link "Back"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "No"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).to have_text("2018 to 2019")
    expect(page).to have_text("2019 to 2020")
    expect(page).to have_text("2020 to 2021")
    expect(page).to have_text("2021 to 2022")

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))

    # Check your answers page includes qualifications questions
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_itt_subject.questions.single_subject", qualification: "undergraduate initial teacher training (ITT)", subject: "mathematics"))
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You’re eligible for an additional payment")
    expect(page).to have_field("£2,000 school targeted retention incentive")
    expect(page).to have_selector('input[type="radio"]', count: 2)

    choose("£2,000 school targeted retention incentive")

    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as TID data all provided for
    expect(page).not_to have_text(I18n.t("questions.personal_details"))

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
    expect(page).to have_text(I18n.t("forms.select_email.questions.select_email"))

    session = Journeys::AdditionalPaymentsForTeaching::Session.order(created_at: :desc).last
    choose session.answers.teacher_id_user_info["email"]

    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.select_mobile_form.questions.which_number"))

    # - Select the suggested phone number
    choose "01234567890"
    click_on "Continue"

    fill_in "Name on your account", with: "John Doe"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))

    choose "Male"
    click_on "Continue"

    # - Check your answers instead of teacher-reference-number (removed slug)
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))

    click_link "Back"
    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))
  end

  scenario "When user is logged in with Teacher ID and there is no matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    navigate_until_performance_related_questions(expect_induction_question: true)

    # Qualification pages are not skipped
    expect(page).not_to have_text(I18n.t("questions.check_and_confirm_qualification_details"))

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # Check your answers page includes qualifications questions
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_itt_subject.questions.single_subject", qualification: "undergraduate initial teacher training (ITT)", subject: "mathematics"))
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
  end

  scenario "When user is logged in with Teacher ID and NINO is not supplied" do
    set_mock_auth("1234567", {nino: "", date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino: ""}, body: eligible_dqt_body)

    navigate_until_performance_related_questions

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped

    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"
    click_on "Continue"

    choose "£2,000 school targeted retention incentive"
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

    expect(page).to have_text(I18n.t("questions.address.home.title"))
  end

  scenario "When user is logged in with Teacher ID and the qualifications data is incomplete" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    missing_qts_date_body = {
      qualified_teacher_status: {
        qts_date: nil
      }
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    navigate_until_performance_related_questions(expect_induction_question: true)

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))

    # ITT year is not shown as it is blank
    expect(page).not_to have_text(I18n.t("questions.academic_year.undergraduate_itt"))
    choose "Yes"
    click_on "Continue"

    # Asks user for the missing information
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2020 to 2021"
    click_on "Continue"

    # Skips subject question as supplied by DQT

    # - Do you teach subject now?
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))

    # Check your answers page only includes missing qualifications questions
    expect(page).not_to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_itt_subject.questions.which_subject", qualification: "undergraduate initial teacher training (ITT)"))
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    expect(page).not_to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
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

    navigate_until_performance_related_questions(expect_induction_question: true)

    # Degree subject is shown because the ITT is ineligible
    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    expect(page).to have_text(I18n.t("questions.itt_subject.undergraduate_itt"))
    expect(page).to have_text("Philosophy")
    expect(page).to have_text(I18n.t("questions.degree_subject"))
    expect(page).to have_text("Mathematics")
  end

  def navigate_until_performance_related_questions(expect_induction_question: false)
    # - Landing (start)
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    click_on "Start now"

    # - Sign in or continue page
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at?
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))

    choose_school school

    # - Are you currently teaching as a qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    if expect_induction_question
      # - Have you completed your induction as an early-career teacher?
      expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

      choose "Yes"
      click_on "Continue"
    else
      expect(page).not_to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))
    end

    # - Are you currently employed as a supply teacher?
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Performance Issues
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.heading"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"
  end
end
