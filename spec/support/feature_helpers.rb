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

  def wait_until_visible(&block)
    page.document.synchronize do
      element = yield
      raise Capybara::ElementNotFound unless element.visible?
    end
  end
end
