require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:eligible_itt_years) { JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(policy_configuration.current_academic_year) }
  let(:academic_date) { Date.new(eligible_itt_years.first.start_year,12,1) }
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
    set_mock_auth(trn, { date_of_birth:, nino: })
    stub_qualified_teaching_statuses_show(trn:, params: { birthdate: date_of_birth, nino: }, body: eligible_dqt_body)

    navigate_past_teacher_details_page

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    # Claim eligibility answers are pre-filled from DQT record
    claim = Claim.all.order(created_at: :desc).limit(1).first
    expect(claim.eligibility.qts_award_year).to eq("on_or_after_cut_off_date")

    # Qualification pages are skipped

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("student_loans.questions.claim_school", financial_year: StudentLoans.current_financial_year))
    click_link "Back"

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "No"
    click_on "Continue"

    # Claim eligibility qualification answers are wiped
    claim.eligibility.reload
    expect(claim.eligibility.qts_award_year).to be nil

    # Qualification pages are no longer skipped

    # - Select qts year
    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end

  scenario "When user is logged in with Teacher ID and there is no matching DQT record" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    navigate_past_teacher_details_page

    # Qualification pages are not skipped

    # - Select qts year
    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end

  scenario "When user is logged in with Teacher ID and the qualifications are not eligible" do
    set_mock_auth("1234567", {nino:, date_of_birth:})
    stub_qualified_teaching_statuses_show(trn:, params: { birthdate: date_of_birth, nino: })

    navigate_past_teacher_details_page

    expect(page).to have_text(I18n.t("questions.check_and_confirm_qualification_details"))
    choose "Yes"
    click_on "Continue"

    # Qualification pages are skipped
    expect(page).to have_text("You’re not eligible for this payment")
  end

  def navigate_past_teacher_details_page
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
  end
end
