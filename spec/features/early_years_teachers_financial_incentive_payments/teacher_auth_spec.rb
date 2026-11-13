require "rails_helper"

RSpec.describe "EYTFIP with teacher auth", feature_flag: [:eytfi_journey] do
  before do
    create(:journey_configuration, :early_years_teachers_financial_incentive_payments)
    create(:eligible_eytfi_provider, name: "Springfield nursery")

    allow(TeacherAuth::Config.instance).to receive(:bypass?).and_return(false)

    # OpenIDConnect::AccessToken#resource_request parses userinfo responses with
    # with_indifferent_access. A plain Hash here hides the Hashie 6 regression:
    # hash subclasses are no longer converted to Mashes supporting method access.
    user_info = OpenIDConnect::ResponseObject::UserInfo.new({
      sub: "teacher-auth-subject",
      trn: "1234567",
      email: "john.doe@example.com",
      verified_name: ["John", "Doe"],
      verified_date_of_birth: "1970-12-13"
    }.with_indifferent_access)

    OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new(
      provider: "teacher",
      uid: user_info.sub,
      info: {email: user_info.email},
      extra: {raw_info: user_info.raw_attributes}
    )
  end

  after do
    OmniAuth.config.mock_auth[:teacher] = nil
  end

  scenario "persists verified details returned by Teacher Auth" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    fill_in "claim[nursery_search_query]", with: "Springfield nursery"
    click_button "Continue"
    choose "Springfield nursery"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"
    expect(page).to have_text "You will need to sign in to your GOV.UK One Login account"
    click_button "Continue"

    expect(page).to have_current_path(
      claim_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name, "qualifications-check")
    )
    answers = Journeys::EarlyYearsTeachersFinancialIncentivePayments::Session.last.answers
    expect(answers.teacher_auth_teacher_reference_number).to eq("1234567")
    expect(answers.teacher_auth_email).to eq("john.doe@example.com")
    expect(answers.teacher_auth_verified_name).to eq("John Doe")
    expect(answers.teacher_auth_verified_date_of_birth).to eq(Date.new(1970, 12, 13))
    expect(answers.teacher_auth_one_login_uid).to eq("teacher-auth-subject")
    expect(answers.identity_confirmed_with_onelogin).to be(true)
  end
end
