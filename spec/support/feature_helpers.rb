module FeatureHelpers
  def start_tslr_claim
    visit root_path
    click_on "Agree and continue"
    TslrClaim.order(:created_at).last
  end

  def choose_qts_year(year = "September 1 2014 – August 31 2015")
    choose year
    click_on "Continue"
  end

  def choose_school(school)
    fill_in :school_search, with: school.name.split(" ").first
    click_on "Search"

    choose school.name
    click_on "Continue"
  end

  def choose_still_teaching(teaching_at = "Yes, at Penistone Grammar School")
    choose teaching_at
    click_on "Continue"
  end

  def choose_subjects_taught
    check "eligible_subjects_biology_taught"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"
  end

  def fill_in_date_of_birth
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"
  end

  def fill_in_address
    fill_in :tslr_claim_address_line_1, with: "123 Main Street"
    fill_in :tslr_claim_address_line_2, with: "Downtown"
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
    choose I18n.t("tslr.answers.student_loan_start_date.one_course.before_first_september_2012")
    click_on "Continue"
  end

  def wait_until_visible(&block)
    page.document.synchronize do
      element = yield
      raise Capybara::ElementNotFound unless element.visible?
    end
  end
end
