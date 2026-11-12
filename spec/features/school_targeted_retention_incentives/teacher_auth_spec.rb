require "rails_helper"

RSpec.describe "STRI with teacher auth", feature_flag: [:new_stri] do
  let(:school) do
    create(:school, :targeted_retention_incentive_payments_eligible)
  end

  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)

    allow(TeacherAuth::SchoolConfig.instance).to receive(:bypass?).and_return(false)

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

    OmniAuth.config.mock_auth[:teacher_school] = OmniAuth::AuthHash.new(
      provider: "teacher_school",
      uid: user_info.sub,
      info: {email: user_info.email},
      extra: {raw_info: user_info.raw_attributes}
    )
  end

  after do
    OmniAuth.config.mock_auth[:teacher_school] = nil
  end

  scenario "persists verified details returned by Teacher Auth" do
    visit landing_page_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name)
    click_link "Start now"

    fill_in "What school do you teach at?", with: school.name
    click_button "Continue"
    choose school.name
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "You will need to sign in to your GOV.UK One Login account"
    click_button "Continue"

    expect(page).to have_current_path(
      claim_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name, "query-teacher-details")
    )
    answers = Journeys::SchoolTargetedRetentionIncentivePayments::Session.last.answers
    expect(answers.teacher_auth_teacher_reference_number).to eq("1234567")
    expect(answers.teacher_auth_email).to eq("john.doe@example.com")
    expect(answers.teacher_auth_verified_name).to eq("John Doe")
    expect(answers.teacher_auth_verified_date_of_birth).to eq(Date.new(1970, 12, 13))
    expect(answers.teacher_auth_one_login_uid).to eq("teacher-auth-subject")
    expect(answers.identity_confirmed_with_onelogin).to be(true)
  end
end
