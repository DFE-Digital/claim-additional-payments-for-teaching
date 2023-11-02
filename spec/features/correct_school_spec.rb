require "rails_helper"

RSpec.feature "Logs in with TID, confirms teacher details and displays school from TPS" do
  include OmniauthMockHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:eligible_school) { create(:school, :combined_journey_eligibile_for_all) }
  let!(:ineligible_school) { create(:school, :early_career_payments_ineligible, :levelling_up_premium_payments_ineligible) }
  let(:trn) { "1234567" }

  before do
    freeze_time
    set_mock_auth(trn)
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects suggested school and then changes selection" do
    navigate_to_correct_school_page(tps: :inside_window, school: eligible_school)

    # - correct-school page
    expect(page).to have_text(eligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode. Use at least three characters.")

    # - Select the suggested school
    choose(eligible_school.name)
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.school.id).to eq(eligible_school.id)
      expect(c.eligibility.school_somewhere_else).to eq(false)
    end

    click_on "Back"

    # - current-school page
    expect(page).to have_text(eligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode. Use at least three characters.")

    # - Select the suggested school
    choose("Somewhere else")
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page).not_to have_text(eligible_school.name)

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.school).to be_nil
      expect(c.eligibility.school_somewhere_else).to eq(true)
    end
  end

  scenario "Most recent TPS is outside window - skips directly to current-school" do
    navigate_to_correct_school_page(tps: :outside_window, school: eligible_school)

    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page).to have_text("Enter the school name or postcode. Use at least three characters.")
  end

  scenario "TPS school is ineligible, still suggested and TPS inside window" do
    navigate_to_correct_school_page(tps: :inside_window, school: ineligible_school)

    # - correct-school page
    expect(page).to have_text(ineligible_school.name)
    expect(page).not_to have_text("Enter the school name or postcode. Use at least three characters.")

    # - Select the suggested school
    choose(ineligible_school.name)
    click_on "Continue"

    # - School is ineligible despite it is the school suggested from TPS
    expect(page).to have_text("The school you have selected is not eligible")

    click_on "Change school"

    # - Goes to current-school
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page).to have_text("Enter the school name or postcode. Use at least three characters.")

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.school).to be_nil
      expect(c.eligibility.school_somewhere_else).to eq(true)
    end
  end

  def navigate_to_correct_school_page(tps:, school:)
    recent_tps_full_months = TeachersPensionsService::RECENT_TPS_FULL_MONTHS

    case tps
    when :inside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, end_date: recent_tps_full_months.ago, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    when :outside_window
      create(:teachers_pensions_service, teacher_reference_number: trn, end_date: (recent_tps_full_months + 2.months).ago, school_urn: school.establishment_number, la_urn: school.local_authority.code)
    end

    visit landing_page_path(EarlyCareerPayments.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("early_career_payments.questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.details_correct"))

    choose "Yes"
    click_on "Continue"
  end
end
