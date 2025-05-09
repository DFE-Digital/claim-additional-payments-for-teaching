require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
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

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with Teacher ID and there is a matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    navigate_past_sign_in_page

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    expect(page).to have_text(I18n.t("student_loans.questions.academic_year"))
    expect(page).to have_text(itt_year.to_s)
    choose "Yes"
    click_on "Continue"

    # Claim eligibility answers are pre-filled from DQT record
    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.qts_award_year).to eq("on_or_after_cut_off_date")

    # Qualification pages are skipped

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("student_loans.forms.claim_school.questions.claim_school", financial_year: Policies::StudentLoans.current_financial_year))
    click_link "Back"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "No"
    click_on "Continue"

    # Claim eligibility qualification answers are wiped
    session.reload
    expect(session.answers.qts_award_year).to be nil

    # Qualification pages are no longer skipped

    # - Select qts year
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
  end

  scenario "When user is logged in with Teacher ID and there is no matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    navigate_past_sign_in_page

    # Qualification pages are not skipped

    # - Select qts year
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
  end

  scenario "When user is logged in with Teacher ID and the qualifications are not eligible" do
    set_mock_auth(trn, {nino:, date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:})

    navigate_past_sign_in_page

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped
    expect(page).to have_text("You’re not eligible for this payment")
  end

  scenario "When user is logged in with Teacher ID and the qualifications data is incomplete" do
    set_mock_auth(trn, {nino:, date_of_birth:})
    missing_qts_date_body = {
      qualified_teacher_status: {
        qts_date: nil
      }
    }
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: missing_qts_date_body)

    navigate_past_sign_in_page

    # Qualification pages are not skipped

    # - Select qts year
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
  end

  def navigate_past_sign_in_page
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
  end
end
