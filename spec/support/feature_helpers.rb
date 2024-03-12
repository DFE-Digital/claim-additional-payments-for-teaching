module FeatureHelpers
  def choose_teaching_maths_or_physics(response = "Yes")
    choose response
    click_on "Continue"
  end

  def choose_initial_teacher_training_subject(response = "Maths")
    choose response
    click_on "Continue"
  end

  def choose_initial_teacher_training_subject_specialism(response = "Physics")
    choose response
    click_on "Continue"
  end

  def start_student_loans_claim
    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
    skip_tid
    choose_qts_year
    Claim.by_policy(Policies::StudentLoans).order(:created_at).last
  end

  def choose_qts_year(option = :on_or_after_cut_off_date)
    choose "claim_eligibility_attributes_qts_award_year_#{option}"
    click_on "Continue"
  end

  def choose_school(school)
    fill_in :school_search, with: school.name.sub("The ", "").split(" ").first

    # Clears the autocomplete when JS is enabled
    click_button "Continue" if RSpec.current_example.metadata[:js].present?

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

  def choose_leadership
    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"
  end

  def fill_in_date_of_birth
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"
  end

  def fill_in_address
    fill_in :claim_address_line_1, with: "123 Main Street"
    fill_in :claim_address_line_2, with: "Downtown"
    fill_in "Town or city", with: "Twin Peaks"
    fill_in "County", with: "Washington"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"
  end

  def answer_student_loan_plan_questions
    choose("Yes")
    click_on "Continue"
    choose("England")
    click_on "Continue"
    choose("1")
    click_on "Continue"
    choose I18n.t("answers.student_loan_start_date.one_course.before_first_september_2012")
    click_on "Continue"
  end

  # Signs in as a user with the service operator role. Returns the signed-in User record.
  def sign_in_as_service_operator
    user = create(:dfe_signin_user)
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    user
  end

  def sign_in_to_admin_with_role(role_code, user_id = "123")
    stub_dfe_sign_in_with_role(role_code, user_id)
    visit admin_sign_in_path
    click_on "Sign in"
  end

  def wait_until_visible(&block)
    page.document.synchronize do
      element = yield
      raise Capybara::ElementNotFound unless element.visible?
    end
  end

  # Early-Career Payment Policy specific helpers
  def start_early_career_payments_claim
    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    Claim.by_policy(Policies::EarlyCareerPayments).order(:created_at).last
  end

  def start_levelling_up_premium_payments_claim
    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    Claim.by_policy(LevellingUpPremiumPayments).order(:created_at).last
  end

  def get_otp_from_email
    ActionMailer::Base.deliveries
      .last[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first
  end

  def skip_tid
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"
  end

  # This is a workaround for some poorly written older feature specs which
  # update claim attributes directly in order to skip pages in the user
  # journey. It should not be used when writing new feature specs. Its purpose
  # is to spoof the session's record of visited pages in the journey.
  #
  # TODO: refactor all old feature specs which use this method
  def jump_to_claim_journey_page(claim, slug)
    set_slug_sequence_in_session(claim, slug)
    visit claim_path(Journeys.for_policy(claim.policy)::ROUTING_NAME, slug)
  end

  def set_slug_sequence_in_session(claim, slug)
    current_claim = CurrentClaim.new(claims: [claim])
    slug_sequence = Journeys.for_policy(claim.policy).slug_sequence.new(current_claim).slugs
    slug_index = slug_sequence.index(slug)
    visited_slugs = slug_sequence.slice(0, slug_index)

    page.set_rack_session(slugs: visited_slugs)
  end
end
