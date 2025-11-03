require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID teacher reference number page removal" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  before do
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:, email: "kelsie.oberbrunner@example.com"}, phone_number: "01234567890")
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    mock_address_details_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "teacher reference page skipped" do
    navigate_to_teacher_reference_number_page(school:)
    expect(current_path).to eq("/student-loans/check-your-answers")
  end

  def navigate_to_teacher_reference_number_page(school:)
    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    # - Select qts year
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
    choose_qts_year
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("student_loans.forms.claim_school.questions.claim_school", financial_year: Policies::StudentLoans.current_financial_year))
    choose_school school

    # - Which subject do you teach
    check "Physics"
    click_on "Continue"

    #  - Are you still employed to teach at
    expect(page).to have_text(I18n.t("student_loans.forms.still_teaching.questions.claim_school"))
    choose_still_teaching("Yes, at #{school.name}")

    #  - leadership-position question
    expect(page).to have_text(leadership_position_question)
    choose "Yes"
    click_on "Continue"

    #  - mostly-performed-leadership-duties question
    expect(page).to have_text(mostly_performed_leadership_duties_question)
    choose "No"
    click_on "Continue"

    # - Information provided
    expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
    click_on "Continue"

    # - How we will use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped

    # - Student loan amount details
    click_on "Continue"

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))

    choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"

    # - select-email page
    expect(page).to have_text(I18n.t("forms.select_email.questions.select_email"))

    # - Select the suggested email address
    choose "kelsie.oberbrunner@example.com"
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.select_mobile_form.questions.which_number"))

    # - Select the suggested phone number
    choose "01234567890"
    click_on "Continue"

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    choose "Male"
    click_on "Continue"
  end

  private

  def mock_address_details_address_data
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(address_data)
  end

  def address_data
    [
      {
        address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 1, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      },
      {
        address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 10, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      },
      {
        address: "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 11, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      }
    ]
  end
end
