module FeatureHelpers
  def start_student_loans_claim
    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
    skip_tid
    choose_qts_year
    Claim.by_policy(Policies::StudentLoans).order(:created_at).last
  end

  def choose_qts_year(option = :on_or_after_cut_off_date)
    form = Journeys::TeacherStudentLoanReimbursement::QtsYearForm.new(
      journey_session: Journeys::TeacherStudentLoanReimbursement::Session.new,
      journey: Journeys::TeacherStudentLoanReimbursement,
      params: ActionController::Parameters.new
    )

    label = form.radio_options.find { |opt| opt.id == option.to_s }.name

    choose label
    click_on "Continue"
  end

  def choose_school(school)
    question = page.find("h1").text

    expect(page).to have_text(/Which (additional )?school/) # there can be variations of the full text depending on which journey/page
    fill_in question, with: school.name.sub("The ", "").split(" ").first
    click_button "Continue"

    choose school.name
    click_button "Continue"
  end

  def choose_school_js(school)
    question = page.find("h1").text

    expect(page).to have_text(/Which (additional )?school/) # there can be variations of the full text depending on which journey/page
    fill_in question, with: school.name.sub("The ", "").split(" ").first

    within("#school_search__listbox") do
      sleep(1) # seems to aid in success, as if click happens before event is bound
      find("li", text: school.name).click
    end

    click_button "Continue"

    choose school.name
    click_button "Continue"
  end

  def choose_still_teaching(teaching_at = "Yes, at Penistone Grammar School")
    choose teaching_at
    click_on "Continue"
  end

  def choose_subjects_taught
    check "Physics"
    click_on "Continue"
  end

  def fill_in_address
    fill_in "House number or name", with: "123 Main Street"
    fill_in "Building and street", with: "Downtown"
    fill_in "Town or city", with: "Twin Peaks"
    fill_in "County", with: "Washington"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"
  end

  def sign_in_as_service_operator
    user = create(:dfe_signin_user)
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    user
  end

  def sign_in_as_service_admin
    user = create(:dfe_signin_user, :service_admin)
    sign_in_to_admin_with_role(user.role_codes, user.dfe_sign_in_id)
    user
  end

  def sign_in_to_admin_with_role(role_code, user_id = "123")
    stub_dfe_sign_in_with_role(role_code, user_id)
    visit admin_sign_in_path
    click_on "Sign in"
  end

  def sign_in_with_admin(admin)
    stub_dfe_sign_in_with_role(admin.role_codes, admin.dfe_sign_in_id)
    visit admin_sign_in_path
    click_on "Sign in"
  end

  def wait_until_visible(&block)
    page.document.synchronize do
      element = yield
      raise Capybara::ElementNotFound unless element.visible?
    end
  end

  def start_targeted_retention_incentive_payments_claim
    visit new_claim_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)
  end

  def get_otp_from_email
    ActionMailer::Base
      .deliveries
      .last
      .personalisation[:one_time_password]
  end

  def skip_tid
    # First click through the new eligibility intro page if present
    if page.has_text?("Check you’re elegible for a targeted retention incentive payment", wait: 0)
      click_on "Start eligibility check"
    end

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"
  end

  def click_through_check_eligibility_intro
    if page.has_text?("Check you’re elegible for a targeted retention incentive payment", wait: 0)
      click_on "Start eligibility check"
    end
  end

  # This is a workaround for some poorly written older feature specs which
  # update claim attributes directly in order to skip pages in the user
  # journey. It should not be used when writing new feature specs. Its purpose
  # is to spoof the session's record of visited pages in the journey.
  #
  # TODO: refactor all old feature specs which use this method
  def jump_to_claim_journey_page(journey_session:, slug:)
    journey = Journeys.for_routing_name(journey_session.journey)
    visit claim_path(journey::ROUTING_NAME, slug)
  end

  def sign_in_with_one_login
    mock_one_login_auth

    expect(page).to have_content("Sign in with GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"
  end

  def idv_with_one_login
    mock_one_login_idv

    expect(page).to have_content("prove your identity through GOV.UK One Login")
    click_button "Continue"
  end

  def sign_in_and_idv_with_one_login
    mock_one_login_auth

    expect(page).to have_content("Sign in with GOV.UK One Login")
    click_button "Continue"

    mock_one_login_idv

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("You’ve successfully proved your identity with GOV.UK One Login")
    click_button "Continue"
  end

  def idv_with_one_login_with_return_codes
    mock_one_login_idv_with_return_codes

    expect(page).to have_content("prove your identity through GOV.UK One Login")
    click_button "Continue"
  end

  def task_status(task_name)
    find(
      :xpath,
      "//h2[contains(@class, 'app-task-list__section') and contains(., '#{task_name}')]/following-sibling::ul//strong[contains(@class, 'govuk-tag')]"
    ).text
  end
end
