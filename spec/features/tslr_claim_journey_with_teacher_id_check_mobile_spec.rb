require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID mobile check" do
  include OmniauthMockHelper
  include StudentLoansHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:phone_number) { "01234567890" }

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

  scenario "Select mobile number to be contacted" do
    # - Selects suggested phone number

    navigate_to_check_mobile_page(school:)

    expect(page).to have_text(I18n.t("questions.select_phone_number.heading"))

    # - Select the suggested phone number
    choose(phone_number)

    click_on "Continue"

    # -  Student loan amount details
    expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))

    claims = Claim.order(created_at: :desc).limit(2)

    claims.each do |c|
      expect(c.mobile_number).to eq(phone_number)
      expect(c.provide_mobile_number).to eq(true)
      expect(c.mobile_check).to eq("use")
    end

    # - Select to use an alternative phone number

    click_on "Back"

    # - Select A different mobile number
    choose(I18n.t("questions.select_phone_number.alternative"))
    click_on "Continue"

    # - Enter your phone number
    expect(page).to have_text("To verify your mobile number we will send you a text message with a 6-digit passcode. You can enter the passcode on the next screen.")

    claims.reload.each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(nil)
      expect(c.mobile_check).to eq("alternative")
    end

    # - Choose not to be contacted by phone

    click_on "Back"

    # - Choose not to be contacted by mobile
    choose(I18n.t("questions.select_phone_number.decline"))
    click_on "Continue"

    # - Student loan amount details
    expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))

    claims.reload.each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(false)
      expect(c.mobile_check).to eq("declined")
    end
  end

  def navigate_to_check_mobile_page(school:)
    visit landing_page_path(StudentLoans.routing_name)

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
    expect(page).to have_text(I18n.t("questions.qts_award_year"))
    choose_qts_year
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("student_loans.questions.claim_school", financial_year: StudentLoans.current_financial_year))
    choose_school school

    # - Which subject do you teach
    check "Physics"
    click_on "Continue"

    #  - Are you still employed to teach at
    expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))
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
    expect(page).to have_text("you can claim back the student loan repayments you made between #{StudentLoans.current_financial_year}.")
    click_on "Continue"

    # - How we will use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(StudentLoans.routing_name, "address"))

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))

    choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
    click_on "Continue"

    # - select-email page
    expect(page).to have_text(I18n.t("questions.select_email.heading"))

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.select_phone_number.heading"))
  end

  private

  def mock_address_details_address_data
    allow_any_instance_of(ClaimsController).to receive(:address_data) do |controller|
      controller.instance_variable_set(:@address_data, address_data)
      address_data
    end
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
