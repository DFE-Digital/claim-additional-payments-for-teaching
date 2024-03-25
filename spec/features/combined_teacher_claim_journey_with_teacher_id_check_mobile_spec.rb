require "rails_helper"

RSpec.feature "Combined journey with Teacher ID mobile check" do
  include OmniauthMockHelper
  include ClaimsControllerHelper

  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:eligible_itt_years) { JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(journey_configuration.current_academic_year) }
  let(:academic_date) { Date.new(eligible_itt_years.first.start_year, 12, 1) }
  let(:itt_year) { AcademicYear.for(academic_date) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:alt_phone_number) { "01234567891" }
  let(:otp_code) { "010101" }
  let(:eligible_dqt_body) do
    {
      qualified_teacher_status: {
        qts_date: academic_date.to_s
      }
    }
  end

  before do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    stub_otp_verification(otp_code:)
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)
  end

  after do
    set_mock_auth(nil)
  end

  scenario "User chooses the mobile number from Teacher ID" do
    navigate_to_check_mobile_page
    mobile_number_selection(:use)
    fill_in_remaining_details
    review_and_submit
  end

  scenario "User chooses an alternative mobile number" do
    navigate_to_check_mobile_page
    mobile_number_selection(:alternative)
    fill_in_remaining_details
    review_and_submit
  end

  scenario "User chooses not to be contacted by mobile" do
    navigate_to_check_mobile_page
    mobile_number_selection(:declined)
    fill_in_remaining_details
    review_and_submit
  end

  scenario "Changing answer from 'Teacher ID number' to 'A different mobile number'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:use)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:alternative)
    review_and_submit
  end

  scenario "Changing answer from 'Teacher ID number' to 'I do not want to be contacted by mobile'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:use)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:declined)
    review_and_submit
  end

  scenario "Changing answer from 'A different mobile number' to 'Teacher ID number'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:alternative)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:use)
    review_and_submit
  end

  scenario "Changing answer from 'A different mobile number' to 'I do not want to be contacted by mobile'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:alternative)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:declined)
    review_and_submit
  end

  scenario "Changing answer from 'I do not want to be contacted by mobile' to 'Teacher ID number'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:declined)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:use)
    review_and_submit
  end

  scenario "Changing answer from 'I do not want to be contacted by mobile' to 'A different mobile number'" do
    navigate_to_check_mobile_page
    mobile_number_selection(:declined)
    fill_in_remaining_details
    go_back_to_mobile_selection
    mobile_number_selection(:use)
    review_and_submit
  end

  def navigate_to_check_mobile_page
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Landing (start)
    click_on "Start now"

    click_on "Continue with DfE Identity"

    # - Teacher details page
    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    choose_school school

    # - Are you currently teaching as a qualified teacher?
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    choose "No"
    click_on "Continue"

    # - Performance Issues
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - Check and confirm qualifications
    choose "Yes"
    click_on "Continue"

    # - Do you spend at least half of your contracted hours teaching eligible subjects?
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    click_on("Continue")

    # - Eligibility confirmed
    choose "£2,000 levelling up premium payment"
    click_on("Apply now")

    # - How we will use the information you provide
    click_on "Continue"

    # - What is your home address
    click_link(I18n.t("questions.address.home.link_to_manual_address"))
    fill_in_address

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"
  end

  def fill_in_remaining_details
    choose "Building society"
    click_on "Continue"

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    fill_in "Building society roll number", with: "1234/123456789"
    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    choose "Male"
    click_on "Continue"

    # - Are you currently repaying a student loan?
    choose "No"
    click_on "Continue"

    # - Did you take out a Postgraduate Masters or a Postgraduate Doctoral loan?
    choose "No"
    click_on "Continue"
  end

  def review_and_submit
    click_on "Accept and send"
    expect(page).to have_text("We have sent you a confirmation email")
  end

  def mobile_number_selection(choice)
    case choice
    when :use
      use_teacher_id_number
    when :alternative
      provide_alternative_number
    when :declined
      decline_to_be_contacted_by_mobile
    else
      raise "Invalid argument '#{choice}'"
    end
  end

  def use_teacher_id_number
    find("#claim_mobile_check_use").click
    click_on "Continue"
  end

  def provide_alternative_number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    fill_in "claim_mobile_number", with: alt_phone_number
    click_on "Continue"

    fill_in "claim_one_time_password", with: otp_code
    click_on "Confirm"
  end

  def decline_to_be_contacted_by_mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"
  end

  def go_back_to_mobile_selection
    page.first("a[href='#{claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "select-mobile")}']", minimum: 1).click
  end
end
