require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID mobile check" do
  include OmniauthMockHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:alt_phone_number) { "01234567891" }
  let(:otp_code) { "010101" }

  before do
    set_mock_auth(trn, {date_of_birth:, nino:, email: "kelsie.oberbrunner@example.com"}, phone_number: "01234567890")
    stub_dqt_empty_response(trn:)
    stub_otp_verification(otp_code:)
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
    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)

    # - Landing (start)
    click_on "Start now"

    click_on "Continue with DfE Identity"

    # - Teacher details page
    choose "Yes"
    click_on "Continue"

    # - Select qts year
    choose_qts_year
    click_on "Continue"

    # - Which school do you teach at
    choose_school school

    # - Which subject do you teach
    check "Physics"
    click_on "Continue"

    #  - Are you still employed to teach at
    choose_still_teaching("Yes, at #{school.name}")

    #  - leadership-position question
    choose "Yes"
    click_on "Continue"

    #  - mostly-performed-leadership-duties question
    choose "No"
    click_on "Continue"

    # - Eligibility confirmed
    click_on "Continue"

    # - How we will use the information you provide
    click_on "Continue"

    # - Personal details - skipped

    # - Student loan amount details
    expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))
    click_on "Continue"

    # - What is your home address
    click_button(I18n.t("questions.address.home.link_to_manual_address"))
    fill_in_address

    # - Select the suggested email address
    choose "kelsie.oberbrunner@example.com"
    click_on "Continue"
  end

  def fill_in_remaining_details
    # - student-loan-amount page
    click_on "Continue"

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    # - What gender does your school's payroll system associate with you
    choose "Male"
    click_on "Continue"
  end

  def review_and_submit
    click_on "Confirm and send"
    expect(page).to have_text("Claim submitted")
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
    choose "01234567890"
    click_on "Continue"
  end

  def provide_alternative_number
    choose "A different mobile number"
    click_on "Continue"

    fill_in "Mobile number", with: alt_phone_number
    click_on "Continue"

    fill_in "claim-one-time-password-field", with: otp_code
    click_on "Confirm"
  end

  def decline_to_be_contacted_by_mobile
    choose "I do not want to be contacted by mobile"
    click_on "Continue"
  end

  def go_back_to_mobile_selection
    click_link "Change which mobile number should we use to contact you?"
  end
end
