require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  def search_keywords(school)
    school.name.sub("The ", "").split(" ").first
  end

  context "Student Loans claim" do
    before { create(:policy_configuration, :student_loans) }
    let!(:school) { create(:school, :student_loans_eligible) }

    scenario "doesn't select a school from the search results the first time around" do
      claim = start_student_loans_claim

      # Creates a duplicate school to test whether the school search shows closed schools
      duplicate_school = create(:school, :student_loans_eligible, :closed, name: "#{school.name} Duplicate")

      fill_in :school_search, with: school.name
      click_on "Continue"

      click_on "Continue"

      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Select a school from the list")

      expect(page).to have_text(duplicate_school.name)

      choose duplicate_school.name
      click_on "Continue"

      expect(claim.eligibility.reload.claim_school).to eql duplicate_school
      expect(page).to have_text(subjects_taught_question(school_name: duplicate_school.name))
    end

    scenario "searches again to find school" do
      another_school = create(:school, :student_loans_eligible)
      claim = start_student_loans_claim

      fill_in :school_search, with: search_keywords(another_school)
      click_on "Continue"

      click_on "Search again"

      fill_in :school_search, with: search_keywords(school)
      click_on "Continue"

      choose school.name
      click_on "Continue"

      expect(claim.eligibility.reload.claim_school).to eql school
      expect(page).to have_text(subjects_taught_question(school_name: school.name))
    end

    scenario "Claim school search with autocomplete", js: true, flaky: true do
      start_student_loans_claim

      expect(page).to have_text(claim_school_question)
      expect(page).to have_button("Continue")

      fill_in :school_search, with: search_keywords(school)
      find("li", text: school.name).click

      expect(page).to have_button("Continue")

      click_button "Continue"

      expect(page).to have_text(subjects_taught_question(school_name: school.name))
    end

    scenario "Current school search with autocomplete", js: true, flaky: true do
      start_student_loans_claim

      choose_school school
      choose_subjects_taught

      choose_still_teaching "Yes, at another school"

      expect(page).to have_text(I18n.t("questions.current_school"))
      expect(page).to have_button("Continue")

      fill_in :school_search, with: search_keywords(school)
      find("li", text: school.name).click

      expect(page).to have_button("Continue")

      click_button "Continue"

      expect(page).to have_text(leadership_position_question)
    end

    scenario "School search form still works like a normal form if submitted", js: true do
      start_student_loans_claim

      expect(page).to have_text(claim_school_question)
      expect(page).to have_button("Continue")

      fill_in :school_search, with: search_keywords(school)

      expect(page).to have_text(school.name)
      expect(page).to have_button("Continue")

      # First click simply removes focus from the autocomplete when JS is enabled - form is not submitted
      click_button "Continue"

      click_button "Continue"

      expect(page).to have_text("Select your school from the search results.")
      expect(page).to have_text(school.name)
    end

    scenario "Editing school search after autocompletion clears last selection", js: true, flaky: true do
      another_school = create(:school, :student_loans_eligible)
      start_student_loans_claim

      expect(page).to have_text(claim_school_question)
      expect(page).to have_button("Continue")

      fill_in :school_search, with: search_keywords(school)
      find("li", text: school.name).click

      expect(page).to have_button("Continue")

      fill_in :school_search, with: another_search_keywords(school)
      expect(page).to have_text(another_school.name)
      expect(page).to have_button("Continue")

      click_button "Continue"

      expect(page).to have_text("Select your school from the search results.")
      expect(page).to have_text(another_school.name)
    end

    context "with a closed school" do
      let!(:closed_school) { create(:school, :student_loans_eligible, :closed) }

      scenario "Claim school search includes closed schools" do
        start_student_loans_claim

        expect(page).to have_text(claim_school_question)
        expect(page).to have_button("Continue")

        fill_in :school_search, with: search_keywords(closed_school)
        click_button "Continue"

        expect(page).to have_text(closed_school.name)
      end

      scenario "Current school search excludes closed schools" do
        start_student_loans_claim
        choose_school school
        choose_subjects_taught
        choose_still_teaching "Yes, at another school"

        expect(page).to have_text(I18n.t("questions.current_school"))
        expect(page).to have_button("Continue")

        fill_in :school_search, with: search_keywords(closed_school)
        click_button "Continue"

        expect(page).not_to have_text(closed_school.name)
      end

      scenario "Claim school search with autocomplete includes closed schools", js: true do
        start_student_loans_claim

        expect(page).to have_text(claim_school_question)
        expect(page).to have_button("Continue")

        fill_in :school_search, with: search_keywords(closed_school)
        expect(page).to have_text(closed_school.name)
      end

      scenario "Current school search with autocomplete excludes closed schools", js: true do
        start_student_loans_claim

        choose_school school
        choose_subjects_taught
        choose_still_teaching "Yes, at another school"

        expect(page).to have_text(I18n.t("questions.current_school"))
        expect(page).to have_button("Continue")

        fill_in :school_search, with: search_keywords(closed_school)
        expect(page).not_to have_text(closed_school.name)
      end
    end
  end

  context "combined ECP/LUPP journey claim" do
    before { create(:policy_configuration, :additional_payments) }
    let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
    let!(:closed_school) { create(:school, :combined_journey_eligibile_for_all, :closed) }

    scenario "doesn't select a school from the search results the first time around" do
      visit new_claim_path(LevellingUpPremiumPayments.routing_name)

      # - Sign in or continue page
      expect(page).to have_text("You can use a DfE Identity account with this service")
      click_on "Continue without signing in"

      # Creates a duplicate school to test whether the school search shows closed schools
      duplicate_school = create(:school, :student_loans_eligible, :closed, name: "#{school.name} Duplicate")

      fill_in :school_search, with: search_keywords(school)
      click_on "Continue"

      expect(page).to have_link("Back")

      click_on "Continue"

      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Select the school you teach at")

      expect(page).to have_text(school.name)
      expect(page).not_to have_text(duplicate_school.name)
    end
  end
end
