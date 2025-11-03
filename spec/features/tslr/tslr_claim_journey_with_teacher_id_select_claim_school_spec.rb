require "rails_helper"

RSpec.feature "TSLR journey with Teacher ID school playback" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:eligible_school) { create(:school, :student_loans_eligible) }
  let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  before do
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "No schools found in TPS in previous financial year - no playback" do
    navigate_to_claim_school_page(tps: :outside_window, school: eligible_school)

    expect(current_path).to eq("/student-loans/claim-school")
  end

  scenario "Shows and selects suggested eligible claim school" do
    navigate_to_claim_school_page(tps: :inside_window, school: eligible_school)

    expect(current_path).to eq("/student-loans/select-claim-school")
    expect(page).to have_text(I18n.t("student_loans.forms.claim_school.questions.claim_school", financial_year: Policies::StudentLoans.current_financial_year))

    choose(eligible_school.name)
    click_on "Continue"

    expect(current_path).to eq("/student-loans/subjects-taught")

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.claim_school.id).to eq(eligible_school.id)
    expect(session.answers.claim_school_somewhere_else).to eq(false)

    click_on "Back"
    expect(current_path).to eq("/student-loans/select-claim-school")
  end

  scenario "Shows and selects suggested ineligible claim school" do
    navigate_to_claim_school_page(tps: :inside_window, school: ineligible_school)

    expect(current_path).to eq("/student-loans/select-claim-school")
    expect(page).to have_text(I18n.t("student_loans.forms.claim_school.questions.claim_school", financial_year: Policies::StudentLoans.current_financial_year))

    choose(ineligible_school.name)
    click_on "Continue"

    expect(current_path).to eq("/student-loans/ineligible")

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.claim_school.id).to eq(ineligible_school.id)
    expect(session.answers.claim_school_somewhere_else).to eq(false)

    # - Tried all schools button
    click_on("I've tried all of my schools")
    expect(current_path).to eq("/student-loans/ineligible")
    expect(page).to have_text("You're not eligible for this payment")

    # - Go back one
    visit claim_path(Journeys::TeacherStudentLoanReimbursement.routing_name, "ineligible")

    # - Try another school
    click_on "Enter another school"
    expect(current_path).to eq("/student-loans/claim-school")
  end

  def navigate_to_claim_school_page(tps:, school:)
    previous_academic_year = journey_configuration.current_academic_year - 1

    within_beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
    within_end_of_month = Date.new(previous_academic_year.start_year, 10, 31)

    before_beginning_of_month = Date.new(previous_academic_year.start_year, 1, 1)
    before_end_of_month = Date.new(previous_academic_year.start_year, 1, 31)

    case tps
    when :inside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, start_date: within_beginning_of_month, end_date: within_end_of_month, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    when :outside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, start_date: before_beginning_of_month, end_date: before_end_of_month, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    end

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
  end
end
