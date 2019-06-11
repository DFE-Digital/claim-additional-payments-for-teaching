module FeatureHelpers
  def start_tslr_claim
    visit root_path
    click_on "Agree and continue"
    TslrClaim.order(:created_at).last
  end

  def choose_qts_year(year = "September 1 2014 - August 31 2015")
    select year, from: :tslr_claim_qts_award_year
    click_on "Continue"
  end

  def choose_school(school)
    fill_in "School name", with: school.name.split(" ").first
    click_on "Search"

    choose school.name
    click_on "Continue"
  end

  def choose_still_teaching(teaching_at = "Yes, at Penistone Grammar School")
    choose teaching_at
    click_on "Continue"
  end

  def wait_until_visible(element)
    page.document.synchronize do
      raise Capybara::ElementNotFound unless element.visible?
    end
  end
end
