require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID mobile check" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:alt_phone_number) { "01234567891" }
  let(:otp_code) { "010101" }

  before do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    stub_otp_verification(otp_code:)
  end

  after do
    set_mock_auth(nil)
  end

  scenario "User chooses the mobile number from Teacher ID" do
    navigate_to_check_mobile_page

    find("#claim_mobile_check_use").click
    click_on "Continue"

    fill_in_remaining_details_and_submit_claim
  end

  scenario "User chooses an alternative mobile number" do
    navigate_to_check_mobile_page

    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    fill_in "claim_mobile_number", with: alt_phone_number
    click_on "Continue"

    fill_in "claim_one_time_password", with: otp_code
    click_on "Confirm"

    fill_in_remaining_details_and_submit_claim
  end

  scenario "User chooses not to be contacted by mobile" do
    navigate_to_check_mobile_page

    find("#claim_mobile_check_declined").click
    click_on "Continue"

    fill_in_remaining_details_and_submit_claim
  end

  def navigate_to_check_mobile_page
    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

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
    click_link(I18n.t("questions.address.home.link_to_manual_address"))
    fill_in_address

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"
  end

  def fill_in_remaining_details_and_submit_claim
    # - student-loan-amount page
    click_on "Continue"

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

    click_on "Confirm and send"

    expect(page).to have_text("Claim submitted")
  end
end
