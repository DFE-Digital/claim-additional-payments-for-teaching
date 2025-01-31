require "rails_helper"

RSpec.feature "Teacher Identity Sign in", js: true do
  include OmniauthMockHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { journey_configuration.current_academic_year }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  before do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  after do
    set_mock_auth(nil)
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id" do
    # - Teacher selects yes to details confirm
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(page).to have_text("Enter the school name or postcode. Use at least three characters.")

    # check the teacher_id_user_info details are saved to the session
    journey_session = Journeys::AdditionalPaymentsForTeaching::Session.last
    expect(journey_session.answers.teacher_id_user_info).to eq({
      "trn" => "1234567",
      "birthdate" => "1981-01-01",
      "email" => "kelsie.oberbrunner@example.com",
      "email_verified" => "",
      "phone_number" => "01234567890",
      "given_name" => "Kelsie",
      "family_name" => "Oberbrunner",
      "ni_number" => "AB123123A",
      "trn_match_ni_number" => "True"
    })

    # - Teacher selects no to details confirm
    click_on "Back"

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identity account with this service")
    expect(page).to have_text("As you have told us that the information we’ve received using your DfE Identity account is not correct, you cannot use your DfE Identity account with this service.")
    expect(page).to have_text("You can continue to complete an application to check your eligibility and apply for a payment.")

    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))

    # check the teacher_id_user_info details are saved to the session
    journey_session = Journeys::AdditionalPaymentsForTeaching::Session.last
    expect(journey_session.answers.teacher_id_user_info).to eq({
      "trn" => "1234567",
      "birthdate" => "1981-01-01",
      "email" => "kelsie.oberbrunner@example.com",
      "email_verified" => "",
      "phone_number" => "01234567890",
      "given_name" => "Kelsie",
      "family_name" => "Oberbrunner",
      "ni_number" => "AB123123A",
      "trn_match_ni_number" => "True"
    })
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects yes to details confirm but trn missing" do
    set_mock_auth("1234567", {returned_trn: nil})

    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identity account with this service")
    expect(page).to have_text("You don’t currently have a teacher reference number (TRN) assigned to your DfE Identity account.")
  end
end
