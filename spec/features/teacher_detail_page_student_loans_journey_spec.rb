require "rails_helper"

RSpec.feature "Teacher Identity Sign in for TSLR" do
  include OmniauthMockHelper

  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:current_academic_year) { policy_configuration.current_academic_year }

  before do
    set_mock_auth("1234567")
  end

  after do
    set_mock_auth(nil)
  end

  scenario "Teacher makes claim for 'Student Loans' by logging in with teacher_id and selects yes to details confirm" do
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

    expect(page).to have_text(I18n.t("questions.qts_award_year"))

    # check the teacher_id_user_info details are saved to the claim
    claim = Claim.order(:created_at).last
    expect(claim.teacher_id_user_info).to eq({"trn" => "1234567", "birthdate" => "1940-01-01", "given_name" => "Kelsie", "family_name" => "Oberbrunner", "ni_number" => "AB123456C", "trn_match_ni_number" => "True", "email" => "kelsie.oberbrunner@example.com"})

    # check the user_info details from teacher id are saved to the claim
    expect(claim.first_name).to eq("Kelsie")
    expect(claim.surname).to eq("Oberbrunner")
    expect(claim.date_of_birth).to eq(Date.parse("1940-01-01"))
    expect(claim.national_insurance_number).to eq("AB123456C")
    expect(claim.teacher_reference_number).to eq("1234567")
    expect(claim.logged_in_with_tid?).to eq(true)
    expect(claim.details_check).to eq(true)
  end

  scenario "Teacher makes claim for 'Student Loans' by logging in with teacher_id and selects no to details confirm" do
    visit landing_page_path(StudentLoans.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identify account with this service")
    expect(page).to have_text("You can continue to complete an application to check your eligibility and apply for a payment.")

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))

    # check the teacher_id_user_info details are saved to the claim
    claim = Claim.order(:created_at).last
    expect(claim.teacher_id_user_info).to eq({"trn" => "1234567", "birthdate" => "1940-01-01", "given_name" => "Kelsie", "family_name" => "Oberbrunner", "ni_number" => "AB123456C", "trn_match_ni_number" => "True", "email" => "kelsie.oberbrunner@example.com"})

    # check the user_info details from teacher id are not saved to the claim
    expect(claim.first_name).to eq("")
    expect(claim.surname).to eq("")
    expect(claim.date_of_birth).to eq(nil)
    expect(claim.national_insurance_number).to eq("")
    expect(claim.teacher_reference_number).to eq("")
    expect(claim.logged_in_with_tid?).to eq(false)
    expect(claim.details_check).to eq(false)
  end

  scenario "Teacher makes claim for 'Student Loans' selects not to log in with teacher_id" do
    visit landing_page_path(StudentLoans.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    expect(page).to have_text(I18n.t("questions.qts_award_year"))

    # check the teacher_id_user_info details are not saved to the claim
    claim = Claim.order(:created_at).last
    expect(claim.teacher_id_user_info).to eq({})

    # check the user_info details from teacher id are not saved to the claim
    expect(claim.first_name).to eq("")
    expect(claim.surname).to eq("")
    # expect(claim.date_of_birth).to eq(nil)
    # expect(claim.national_insurance_number).to eq("")
    # expect(claim.teacher_reference_number).to eq("")
    # expect(claim.logged_in_with_tid?).to eq(nil)
    # expect(claim.details_check).to eq(nil)
  end
end
