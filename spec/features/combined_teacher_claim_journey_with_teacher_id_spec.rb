require "rails_helper"

RSpec.feature "Combined journey with Teacher ID" do
  include OmniauthMockHelper

  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: AcademicYear.new(2023)) }
  let(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:eligible_itt_years) { Policies::TargetedRetentionIncentivePayments.selectable_itt_years_for_claim_year(journey_configuration.current_academic_year) }
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
  let(:dqt_higher_education_qualification) do
    create(
      :dqt_higher_education_qualification,
      teacher_reference_number: trn,
      date_of_birth: Date.parse(date_of_birth),
      subject_code: "G100",
      description: "Mathematics"
    )
  end

  before do
    school
    stub_otp_verification
    dqt_higher_education_qualification
  end

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with Teacher ID and there is a matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    navigate_until_performance_related_questions

    expect(page).to have_text("Check and confirm your qualification details")
    expect(page).to have_text("Academic year you completed your undergraduate initial teacher training (ITT)")
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped

    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text("Check your answers")
    expect(page).to have_text("Eligibility details")
    expect(page).to have_text("By selecting continue you are confirming that, to the best of your knowledge, the details you are providing are correct.")

    ["Identity details", "Payment details", "Student loan details"].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    # Check your answers page does not include qualifications questions
    expect(page).not_to have_text("Which route into teaching did you take?")
    expect(page).not_to have_text("Did you do your undergraduate initial teacher training (ITT) in mathematics?")
    expect(page).not_to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    expect(page).not_to have_text("Do you have a degree in an eligible subject?")

    # Go back to the qualification details page
    click_link "Back"

    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
    click_link "Back"

    expect(page).to have_text("Check and confirm your qualification details")
    choose "No"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text("Which route into teaching did you take?")

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    expect(page).to have_text("2018 to 2019")
    expect(page).to have_text("2019 to 2020")
    expect(page).to have_text("2020 to 2021")
    expect(page).to have_text("2021 to 2022")

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text("Check your answers")

    # Check your answers page includes qualifications questions
    expect(page).to have_text("Which route into teaching did you take?")
    expect(page).to have_summary_item(
      key: "Which subject did you do your undergraduate initial teacher training (ITT) in?",
      value: "Mathematics"
    )
    expect(page).to have_summary_item(
      key: "In which academic year did you complete your undergraduate initial teacher training (ITT)?",
      value: "2018 to 2019"
    )

    expect(page).not_to have_text("Do you have a degree in an eligible subject?")

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You’re eligible for a targeted retention incentive payment")
    expect(page).to have_text("targeted retention incentive payment of: £2,000")

    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as TID data all provided for
    expect(page).not_to have_text("Personal details")

    # - What is your home address
    expect(page).to have_text("What is your home address?")

    click_on("Enter your address manually")

    # - What is your address
    expect(page).to have_text("What is your address?")

    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    # - Email address
    expect(page).to have_text("Which email address should we use to contact you?")

    session = Journeys::TargetedRetentionIncentivePayments::Session.order(created_at: :desc).last
    choose session.answers.teacher_id_user_info["email"]

    click_on "Continue"

    expect(page).to have_text("Which mobile number should we use to contact you?")

    # - Select the suggested phone number
    choose "01234567890"
    click_on "Continue"

    fill_in "Name on your account", with: "John Doe"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text("How is your gender recorded on your school’s payroll system?")

    choose "Male"
    click_on "Continue"

    # - Check your answers instead of teacher-reference-number (removed slug)
    expect(page).to have_text("Check your answers")

    click_link "Back"
    expect(page).to have_text("How is your gender recorded on your school’s payroll system?")
  end

  scenario "When user is logged in with Teacher ID and there is no matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    navigate_until_performance_related_questions

    # Qualification pages are not skipped
    expect(page).not_to have_text("Check and confirm your qualification details")

    # - What route into teaching did you take?
    expect(page).to have_text("Which route into teaching did you take?")

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")

    choose "Yes"
    click_on "Continue"

    # Check your answers page includes qualifications questions
    expect(page).to have_text("Which route into teaching did you take?")
    expect(page).to have_summary_item(
      key: "Which subject did you do your undergraduate initial teacher training (ITT) in?",
      value: "Mathematics"
    )
    expect(page).to have_summary_item(
      key: "In which academic year did you complete your undergraduate initial teacher training (ITT)?",
      value: "#{itt_year.start_year} to #{itt_year.end_year}"
    )
    expect(page).not_to have_text("Do you have a degree in an eligible subject?")
  end

  scenario "When user is logged in with Teacher ID and NINO is not supplied" do
    set_mock_auth("1234567", {nino: "", date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino: ""}, body: eligible_dqt_body)

    navigate_until_performance_related_questions

    expect(page).to have_text("Check and confirm your qualification details")
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped

    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")

    choose "Yes"
    click_on "Continue"
    click_on "Continue"

    click_on "Apply now"
    click_on "Continue"

    # - Personal details
    expect(page).to have_text("Personal details")

    # - not shown
    expect(page).not_to have_text("What is your full name?")
    expect(page).not_to have_text("What is your date of birth?")

    # - shown
    expect(page).to have_text("What is your National Insurance number?")

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_text("What is your home address?")
  end

  scenario "When user is logged in with Teacher ID and the qualifications data is incomplete" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    missing_qts_date_body = {
      qualified_teacher_status: {
        qts_date: nil
      }
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    navigate_until_performance_related_questions

    expect(page).to have_text("Check and confirm your qualification details")

    # ITT year is not shown as it is blank
    expect(page).not_to have_text("Academic year you completed your undergraduate initial teacher training (ITT)")
    choose "Yes"
    click_on "Continue"

    # Asks user for the missing information
    expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")

    choose "2020 to 2021"
    click_on "Continue"

    # Skips subject question as supplied by DQT

    # - Do you teach subject now?
    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text("Check your answers")

    # Check your answers page only includes missing qualifications questions
    expect(page).not_to have_text("Which route into teaching did you take?")
    expect(page).not_to have_text("Which subject did you do your undergraduate initial teacher training (ITT) in?")
    expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    expect(page).not_to have_text("Do you have a degree in an eligible subject?")
  end

  scenario "When user is logged in with Teacher ID and the ITT subject is ineligible" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    missing_qts_date_body = {
      initial_teacher_training: {
        subject1: "philosophy",
        subject1_code: "TEST"
      }
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    navigate_until_performance_related_questions

    # Degree subject is shown because the ITT is ineligible
    expect(page).to have_text("Check and confirm your qualification details")
    expect(page).to have_text("Subject you did your undergraduate initial teacher training (ITT) in")
    expect(page).to have_text("Philosophy")
    expect(page).to have_text("Subject you did your degree in")
    expect(page).to have_text("Mathematics")
  end

  def navigate_until_performance_related_questions
    # - Landing (start)
    visit landing_page_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)
    click_on "Start now"

    # - Check eligibility intro
    expect(page).to have_text("Check you're eligible for a targeted retention incentive payment")
    click_on "Start eligibility check"

    # - Sign in or continue page
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text("Check and confirm your personal details")
    expect(page).to have_text("Are these details correct?")

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at?
    expect(page).to have_text("Which school do you teach at?")
    expect(page.title).to have_text("Which school do you teach at?")

    choose_school school

    # - Are you currently teaching as a qualified teacher?
    expect(page).to have_text("Are you currently teaching as a qualified teacher?")

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher?
    expect(page).to have_text("Are you currently employed as a supply teacher?")

    choose "No"
    click_on "Continue"

    # - Performance Issues
    expect(page).to have_text("Tell us if you are currently under any performance measures or disciplinary action")

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"
  end
end
