require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID email check" do
  include OmniauthMockHelper
  include StudentLoansHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:email) { "kelsie.oberbrunner@example.com" }
  let(:new_email) { "new.email@example" }
  let(:postcode) { "SO16 9FX" }

  before do
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    mock_address_details_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects suggested email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.select_mobile_form.questions.which_number"))

    session = Journeys::TeacherStudentLoanReimbursement::Session.order(created_at: :desc).last
    answers = session.answers

    expect(answers.email_address).to eq("kelsie.oberbrunner@example.com")
    expect(answers.email_address_check).to eq(true)
    expect(answers.email_verified).to eq(true)
  end

  scenario "Select a different email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text("A different email address")

    # - Select A different email address
    find("#claim_email_address_check_false").click
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.email_address.hint1"))

    session = Journeys::TeacherStudentLoanReimbursement::Session.order(created_at: :desc).last
    answers = session.answers

    expect(answers.email_address).to eq(nil)
    expect(answers.email_address_check).to eq(false)
    expect(answers.email_verified).to eq(nil)
  end

  scenario "Selects suggested email address and then changes to a different email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"

    click_on "Back"

    find("#claim_email_address_check_false").click
    click_on "Continue"

    session = Journeys::TeacherStudentLoanReimbursement::Session.order(created_at: :desc).last
    answers = session.answers

    expect(answers.email_address).to eq(nil)
    expect(answers.email_address_check).to eq(false)
    expect(answers.email_verified).to eq(nil)
  end

  scenario "Selects a different email address and then changes to the suggested email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select A different email address
    find("#claim_email_address_check_false").click
    click_on "Continue"

    click_on "Back"

    find("#claim_email_address_check_true").click
    click_on "Continue"

    session = Journeys::TeacherStudentLoanReimbursement::Session.order(created_at: :desc).last
    answers = session.answers

    expect(answers.email_address).to eq(email)
    expect(answers.email_address_check).to eq(true)
    expect(answers.email_verified).to eq(true)
  end

  def navigate_to_check_email_page(school:)
    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

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

    # - student-loan-amount page
    expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
    click_on "Continue"

    # - How we will use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("the Student Loans Company")
    click_on "Continue"

    # - Personal details - skipped

    # - Student loan amount details
    expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))
    click_on "Continue"

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    fill_in "Postcode", with: postcode
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
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
        postcode:
      },
      {
        address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 10, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode:
      },
      {
        address: "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 11, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode:
      }
    ]
  end
end
