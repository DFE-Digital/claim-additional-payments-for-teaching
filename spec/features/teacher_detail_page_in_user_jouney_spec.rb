require "rails_helper"

RSpec.feature "Teacher Identity Sign in" do
  include OmniauthMockHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { policy_configuration.current_academic_year }

  after do
    set_mock_auth(nil)
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects yes to details confirm" do
    set_mock_auth("1234567")

    visit landing_page_path(EarlyCareerPayments.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page).to have_text("Enter the school name or postcode. Use at least three characters.")

    # check the teacher_id_user_info details are saved to the claim
    claim = Claim.order(:created_at).last
    expect(claim.teacher_id_user_info).to eq({"trn" => "1234567", "birthdate" => "1940-01-01", "email" => "kelsie.oberbrunner@example.com", "phone_number" => "01234567890", "given_name" => "Kelsie", "family_name" => "Oberbrunner", "ni_number" => "AB123456C", "trn_match_ni_number" => "True"})
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects no to details confirm" do
    set_mock_auth("1234567")

    visit landing_page_path(EarlyCareerPayments.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identity account with this service")
    expect(page).to have_text("As you have told us that the information we’ve received using your DfE Identity account is not correct, you cannot use your DfE Identity account with this service.")
    expect(page).to have_text("You can continue to complete an application to check your eligibility and apply for a payment.")

    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    # check the teacher_id_user_info details are saved to the claim
    claim = Claim.order(:created_at).last
    expect(claim.teacher_id_user_info).to eq({"trn" => "1234567", "birthdate" => "1940-01-01", "given_name" => "Kelsie", "family_name" => "Oberbrunner", "ni_number" => "AB123456C", "phone_number" => "01234567890", "trn_match_ni_number" => "True", "email" => "kelsie.oberbrunner@example.com"})
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects yes to details confirm but trn missing" do
    set_mock_auth("1234567", {returned_trn: nil})

    visit landing_page_path(EarlyCareerPayments.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identity account with this service")
    expect(page).to have_text("You don’t currently have a teacher reference number (TRN) assigned to your DfE Identity account.")
  end
end
