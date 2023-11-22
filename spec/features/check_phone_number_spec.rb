require "rails_helper"

RSpec.feature "Logs in with TID, confirms teacher details and displays phone number from DfE Identity" do
  include OmniauthMockHelper
  include ClaimsControllerHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:trn) { "1234567" }
  let(:phone_number) { "01234567890" }

  before do
    freeze_time
    set_mock_auth(trn, phone_number:)
    mock_claims_controller_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects suggested phone number" do
    navigate_to_check_phone_number_page(school:)

    expect(page).to have_text(I18n.t("early_career_payments.questions.select_phone_number.heading"))
    expect(page).to have_text(phone_number)

    # - Select the suggested phone number
    find("#claim_mobile_check_use").click
    click_on "Continue"

    # - Choose bank or building society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(phone_number)
      expect(c.provide_mobile_number).to eq(true)
      expect(c.mobile_check).to eq("use")
    end
  end

  scenario "Select to use an alternative phone number" do
    navigate_to_check_phone_number_page(school:)

    expect(page).to have_text(I18n.t("early_career_payments.questions.select_phone_number.alternative"))

    # - Select A different mobile number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    # - Enter your phone number
    expect(page).to have_text("To verify your mobile number we will send you a text message with a 6-digit passcode. You can enter the passcode on the next screen.")

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(nil)
      expect(c.mobile_check).to eq("alternative")
    end
  end

  scenario "Choose not to be contacted by phone" do
    navigate_to_check_phone_number_page(school:)

    expect(page).to have_text(I18n.t("early_career_payments.questions.select_phone_number.decline"))

    # - Choose not to be contacted by mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"

    # - Choose bank or building society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(false)
      expect(c.mobile_check).to eq("declined")
    end
  end

  scenario "Selects suggested phone number and then changes to an alternative phone number" do
    navigate_to_check_phone_number_page(school:)

    # - Select the suggested phone number
    find("#claim_mobile_check_use").click
    click_on "Continue"

    click_on "Back"

    # - Select A different mobile number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(nil)
      expect(c.mobile_check).to eq("alternative")
    end
  end

  scenario "Selects suggested phone number and then changes to decline to be contacted by phone" do
    navigate_to_check_phone_number_page(school:)

    # - Select the suggested phone number
    find("#claim_mobile_check_use").click
    click_on "Continue"

    click_on "Back"

    # - Choose not to be contacted by mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(false)
      expect(c.mobile_check).to eq("declined")
    end
  end

  scenario "Selects an alternative phone number and then changes to use the suggested phone number" do
    navigate_to_check_phone_number_page(school:)

    # - Select A different mobile number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    click_on "Back"

    # - Select the suggested phone number
    find("#claim_mobile_check_use").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(phone_number)
      expect(c.provide_mobile_number).to eq(true)
      expect(c.mobile_check).to eq("use")
    end
  end

  scenario "Selects an alternative phone number and then changes to decline to be contacted by phone" do
    navigate_to_check_phone_number_page(school:)

    # - Select A different mobile number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    click_on "Back"

    # - Choose not to be contacted by mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(false)
      expect(c.mobile_check).to eq("declined")
    end
  end

  scenario "Declines to be contacted by phone and then changes to use the suggested phone number" do
    navigate_to_check_phone_number_page(school:)

    # - Choose not to be contacted by mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"

    click_on "Back"

    # - Select the suggested phone number
    find("#claim_mobile_check_use").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(phone_number)
      expect(c.provide_mobile_number).to eq(true)
      expect(c.mobile_check).to eq("use")
    end
  end

  scenario "Declines to be contacted by phone and then changes to an alternative phone number" do
    navigate_to_check_phone_number_page(school:)

    # - Choose not to be contacted by mobile
    find("#claim_mobile_check_declined").click
    click_on "Continue"

    click_on "Back"

    # - Select A different mobile number
    find("#claim_mobile_check_alternative").click
    click_on "Continue"

    Claim.order(created_at: :desc).limit(2).each do |c|
      expect(c.mobile_number).to eq(nil)
      expect(c.provide_mobile_number).to eq(nil)
      expect(c.mobile_check).to eq("alternative")
    end
  end

  def navigate_to_check_phone_number_page(school:)
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

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))

    choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
    click_on "Continue"

    # - Select the suggested email address
    find("#claim_email_address_check_true").click
    click_on "Continue"
  end
end
