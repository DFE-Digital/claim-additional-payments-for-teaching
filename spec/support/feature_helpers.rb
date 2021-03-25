module FeatureHelpers
  def start_maths_and_physics_claim
    visit new_claim_path(MathsAndPhysics.routing_name)
    choose_teaching_maths_or_physics
    Claim.order(:created_at).last
  end

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

  def choose_maths_and_physics_degree(response = "Yes")
    choose response
    click_on "Continue"
  end

  def start_student_loans_claim
    visit new_claim_path(StudentLoans.routing_name)
    choose_qts_year
    Claim.order(:created_at).last
  end

  def choose_qts_year(option = :on_or_after_cut_off_date)
    choose "claim_eligibility_attributes_qts_award_year_#{option}"
    click_on "Continue"
  end

  def choose_school(school)
    fill_in :school_search, with: school.name.sub("The ", "").split(" ").first
    click_on "Search"

    choose school.name
    click_on "Continue"
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
end
