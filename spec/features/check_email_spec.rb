require "rails_helper"

RSpec.feature "Logs in with TID, confirms teacher details and displays email from DfE Identity" do
  include OmniauthMockHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:trn) { "1234567" }
  let(:email) { "kelsie.oberbrunner@example.com" }
  let(:new_email) { "new.email@example" }

  before do
    freeze_time
    set_mock_auth(trn)
    mock_address_details_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects suggested email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.email_address).to eq("kelsie.oberbrunner@example.com")
      expect(c.email_address_check).to eq(true)
      expect(c.email_verified).to eq(true)
    end
  end

  scenario "Select a different email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text("A different email address")

    # - Select A different email address
    find("#claim_email_address_check_false").click
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.email_address_hint1"))

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.email_address).to eq(nil)
      expect(c.email_address_check).to eq(false)
      expect(c.email_verified).to eq(nil)
    end
  end

  scenario "Selects suggested email address and then changes to a different email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"

    click_on "Back"

    find("#claim_email_address_check_false").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.email_address).to eq(nil)
      expect(c.email_address_check).to eq(false)
      expect(c.email_verified).to eq(nil)
    end
  end

  scenario "Selects a different email address and then changes to the suggested email address" do
    navigate_to_check_email_page(school:)

    # - select-email page
    expect(page).to have_text(email)

    # - Select A different email address
    find("#claim_email_address_check_false").click
    click_on "Continue"

    click_on "Back"

    find("#claim_email_address_check_true").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.email_address).to eq(email)
      expect(c.email_address_check).to eq(true)
      expect(c.email_verified).to eq(true)
    end
  end

  def navigate_to_check_email_page(school:)
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

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    choose "2020 to 2021"
    click_on "Continue"

    # User should be redirected to the next question which was previously answered but wiped by the attribute dependency
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    click_on("Continue")

    expect(page).to have_text("You’re eligible for an additional payment")
    choose("£2,000 levelling up premium payment")
    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as all details from TID are valid
    expect(page).not_to have_text(I18n.t("questions.personal_details"))

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))

    choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
    click_on "Continue"
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
