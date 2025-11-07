require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID still teaching school playback" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:eligible_claim_school) { create(:school, :student_loans_eligible) }
  let!(:eligible_school) { create(:school, :student_loans_eligible) }
  let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  before do
    freeze_time

    previous_academic_year = journey_configuration.current_academic_year - 1
    within_beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
    within_end_of_month = Date.new(previous_academic_year.start_year, 10, 31)

    # used for the claim-school school playback, earlier in the journey
    create(:teachers_pensions_service, teacher_reference_number: trn, start_date: within_beginning_of_month, end_date: within_end_of_month, school_urn: eligible_claim_school.establishment_number, la_urn: eligible_claim_school.local_authority.code)

    # used for the still-teaching school playback, the one being tested
    recent_tps_full_months = TeachersPensionsService::RECENT_TPS_FULL_MONTHS
    create(:teachers_pensions_service, teacher_reference_number: trn, end_date: recent_tps_full_months.ago, school_urn: eligible_school.establishment_number, la_urn: eligible_school.local_authority.code)

    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects school" do
    navigate_to_still_teaching_page

    # - Tries to continue without selecting option
    click_on "Continue"
    expect(page).to have_text("Select if you still work at #{eligible_school.name}, another school or no longer teach in England")

    # - Selects suggested school retrieved from TPS
    choose(eligible_school.name)
    click_on "Continue"

    expect(current_path).to eq("/student-loans/leadership-position")

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.claim_school_id).to eq eligible_claim_school.id
    expect(session.answers.current_school_id).to eq eligible_school.id
    expect(session.answers.employment_status).to eq "recent_tps_school"

    # - Selects somewhere else

    click_on "Back"
    choose("Somewhere else")
    click_on "Continue"

    expect(current_path).to eq("/student-loans/current-school")

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.claim_school_id).to eq eligible_claim_school.id
    expect(session.answers.current_school_id).to be_nil
    expect(session.answers.employment_status).to eq "different_school"

    # - Selects No...
    click_on "Back"

    choose("I'm no longer employed to teach at a state-funded secondary school in England")
    click_on "Continue"

    expect(current_path).to eq("/student-loans/ineligible")

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.claim_school_id).to eq eligible_claim_school.id
    expect(session.answers.current_school_id).to be_nil
    expect(session.answers.employment_status).to eq "no_school"
  end

  def navigate_to_still_teaching_page
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

    # - Claim school
    choose(eligible_claim_school.name)
    click_on "Continue"

    # - Select subject
    check "Biology"
    click_on "Continue"

    expect(current_path).to eq("/student-loans/still-teaching-tps")
  end
end
