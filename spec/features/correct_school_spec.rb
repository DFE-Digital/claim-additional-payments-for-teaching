require "rails_helper"

RSpec.feature "Logs in with TID, confirms teacher details and displays school from TPS" do
  include OmniauthMockHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments) }
  let(:eligible_school) { create(:school, :targeted_retention_incentive_payments_eligible) }
  let(:ineligible_school) { create(:school, :targeted_retention_incentive_payments_ineligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  before do
    eligible_school
    ineligible_school
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects suggested school and then changes selection" do
    navigate_to_correct_school_page(tps: :inside_window, school: eligible_school)

    # - correct-school page
    expect(page).to have_text(eligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode using at least 3 characters")

    # - Select the suggested school
    choose(eligible_school.name)
    click_on "Continue"

    expect(page).to have_text("Are you currently teaching as a qualified teacher?")

    session = Journeys::TargetedRetentionIncentivePayments::Session.last
    expect(session.answers.current_school_id).to eq(eligible_school.id)
    expect(session.answers.school_somewhere_else).to eq(false)

    click_on "Back"

    # - current-school page
    expect(page).to have_text(eligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode using at least 3 characters")

    # - Select the suggested school
    choose("Somewhere else")
    click_on "Continue"

    expect(page).to have_text("Which school do you teach at?")
    expect(page).not_to have_text(eligible_school.name)

    session = Journeys::TargetedRetentionIncentivePayments::Session.last
    expect(session.answers.current_school).to be_nil
    expect(session.answers.school_somewhere_else).to eq(true)
  end

  scenario "Most recent TPS is outside window - skips directly to current-school" do
    navigate_to_correct_school_page(tps: :outside_window, school: eligible_school)

    expect(page).to have_text("Which school do you teach at?")
    expect(page).to have_text("Enter the school name or postcode using at least 3 characters")
  end

  scenario "TPS school is ineligible, still suggested and TPS inside window" do
    navigate_to_correct_school_page(tps: :inside_window, school: ineligible_school)

    # - correct-school page
    expect(page).to have_text(ineligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode using at least 3 characters")

    # - Select the suggested school
    choose(ineligible_school.name)
    click_on "Continue"

    # - School is ineligible despite it is the school suggested from TPS
    expect(page).to have_text("The school you have selected is not eligible")

    click_on "Change school"

    # - Goes to current-school
    expect(page).to have_text("Which school do you teach at?")
    expect(page).to have_text("Enter the school name or postcode using at least 3 characters")

    session = Journeys::TargetedRetentionIncentivePayments::Session.last
    expect(session.answers.current_school).to be_nil
    expect(session.answers.school_somewhere_else).to eq(true)
  end

  def navigate_to_correct_school_page(tps:, school:)
    recent_tps_full_months = TeachersPensionsService::RECENT_TPS_FULL_MONTHS

    case tps
    when :inside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, end_date: recent_tps_full_months.ago, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    when :outside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, end_date: (recent_tps_full_months + 2.months).ago, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    end

    visit landing_page_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)

    # - Landing (start)
    expect(page).to have_text("Find out if you are eligible for a targeted retention incentive payment")
    click_on "Start now"

    # - Check eligibility intro
    expect(page).to have_text("Check you’re elegible for a targeted retention incentive payment")
    click_on "Start eligibility check"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text("Check and confirm your personal details")
    expect(page).to have_text("Are these details correct?")

    choose "Yes"
    click_on "Continue"
  end
end
