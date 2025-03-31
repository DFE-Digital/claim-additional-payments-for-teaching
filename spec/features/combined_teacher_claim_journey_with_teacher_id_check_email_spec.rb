require "rails_helper"

RSpec.feature "Combined journey with Teacher ID email check" do
  include OmniauthMockHelper
  include ClaimsControllerHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:email) { "kelsie.oberbrunner@example.com" }
  let(:new_email) { "new.email@example" }

  before do
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    mock_claims_controller_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects email address to be contacted" do
    # - Selects suggested email address
    navigate_to_check_email_page(school:)

    # - select-email page

    # - Select the suggested email address
    choose(email)
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.select_mobile_form.questions.which_number"))

    session = Journeys::AdditionalPaymentsForTeaching::Session.order(created_at: :desc).last

    expect(session.answers.email_address).to eq("kelsie.oberbrunner@example.com")
    expect(session.answers.email_address_check).to eq(true)
    expect(session.answers.email_verified).to eq(true)

    # - Select a different email address
    click_on "Back"

    # - select-email page

    # - Select A different email address
    choose("A different email address")
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.email_address.hint1"))

    session.reload

    expect(session.answers.email_address).to eq(nil)
    expect(session.answers.email_address_check).to eq(false)
    expect(session.answers.email_verified).to eq(nil)
  end

  def navigate_to_check_email_page(school:)
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.question"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    choose "2020 to 2021"
    click_on "Continue"

    # User should be redirected to the next question which was previously answered but wiped by the attribute dependency
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    click_on("Continue")

    expect(page).to have_text("You’re eligible for an additional payment")
    choose("£2,000 school targeted retention incentive")
    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as all details from TID are valid
    expect(page).not_to have_text(I18n.t("questions.personal_details"))

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "address"))

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))

    choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"
  end
end
