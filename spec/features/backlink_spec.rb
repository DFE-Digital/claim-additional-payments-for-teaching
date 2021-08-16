require "rails_helper"

RSpec.feature "Backlinking during a claim" do
  context "with JS enabled", js: true do
    scenario "shows the backlink when needed" do
      visit new_claim_path(StudentLoans.routing_name)
      expect(page).to_not have_link("Back")
      choose_qts_year
      expect(page).to have_link("Back")
      choose_school schools(:penistone_grammar_school)
      click_on "Back"
      expect(page).to have_current_path("/student-loans/claim-school", ignore_query: true)
      click_on "Back"
      expect(page).to have_current_path("/student-loans/claim-school", ignore_query: true)
      click_on "Back"
      expect(page).to have_current_path("/student-loans/existing-session", ignore_query: true)
      expect(page).to_not have_link("Back")
    end
  end

  context "with JS disabled" do
    scenario "hides the backlink" do
      visit new_claim_path(StudentLoans.routing_name)
      expect(page).to_not have_css(".govuk-back-link.govuk-visually-hidden")
      choose_qts_year
      expect(page).to have_css(".govuk-back-link.govuk-visually-hidden")
      choose_school schools(:penistone_grammar_school)
      expect(page).to have_css(".govuk-back-link.govuk-visually-hidden")
    end

    scenario "backlink is not present on pages that exclude it" do
      # ecp journey
      %w[claim eligibility-confirmed eligible-later ineligible].each do |slug|
        ClaimsController.any_instance.stub(:current_template).and_return(slug)
        visit "/early-career-payments/#{slug}"
        expect(page).to_not have_link("Back")
      end
      # student loan journey
      %w[claim eligibility-confirmed ineligible].each do |slug|
        ClaimsController.any_instance.stub(:current_template).and_return(slug)
        visit "/student-loans/#{slug}"
        expect(page).to_not have_link("Back")
      end
      # maths and physics journey
      %w[claim eligibility-confirmed ineligible].each do |slug|
        ClaimsController.any_instance.stub(:current_template).and_return(slug)
        visit "/maths-and-physics/#{slug}"
        expect(page).to_not have_link("Back")
      end
    end
  end
end
