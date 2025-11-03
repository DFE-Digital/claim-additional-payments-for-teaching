require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  def search_keywords(school)
    school.name.sub("The ", "").split(" ").first
  end

  context "Student Loans claim" do
    before { create(:journey_configuration, :student_loans) }
    let!(:school) { create(:school, :student_loans_eligible) }

    scenario "doesn't select a school from the search results the first time around" do
      start_student_loans_claim
      session = Journeys::TeacherStudentLoanReimbursement::Session.last

      # Creates a duplicate school to test whether the school search shows closed schools
      duplicate_school = create(:school, :student_loans_eligible, :closed, name: "#{school.name} Duplicate")

      question = page.find("h1").text
      fill_in question, with: school.name
      click_on "Continue"

      click_on "Continue"

      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Select a school from the list")

      expect(page).to have_text(duplicate_school.name)

      choose duplicate_school.name
      click_on "Continue"

      expect(session.reload.answers.claim_school).to eql duplicate_school
      expect(page).to have_text(subjects_taught_question(school_name: duplicate_school.name))
    end

    scenario "Claim school search with autocomplete", js: true, flaky: true do
      start_student_loans_claim

      expect(page).to have_text(claim_school_question)
      expect(page).to have_button("Continue")

      question = page.find("h1").text
      fill_in question, with: search_keywords(school)
      find("li", text: school.name).click

      expect(page).to have_button("Continue")

      click_button "Continue"

      # flaky test workaround in case the first click on Continue submitted the form
      click_button "Continue" unless /claim-school\?_method=patch/.match?(current_url)

      # Backlink is to the same slug as current (claim-school)
      expect(page).to have_link("Back", href: claim_path(Journeys::TeacherStudentLoanReimbursement.routing_name, "claim-school"))

      choose school.name

      click_button "Continue"

      expect(page).to have_text(subjects_taught_question(school_name: school.name))
    end

    scenario "Current school search with autocomplete", js: true, flaky: true do
      start_student_loans_claim

      choose_school school
      choose_subjects_taught

      choose_still_teaching "Yes, at another school"

      expect(page).to have_text(I18n.t("student_loans.forms.current_school.question"))
      expect(page).to have_button("Continue")

      fill_in I18n.t("student_loans.forms.current_school.question"), with: search_keywords(school)
      find("li", text: school.name).click
      click_button "Continue"

      # Backlink is to the same slug as current (current-school)
      expect(page).to have_link("Back", href: claim_path(Journeys::TeacherStudentLoanReimbursement.routing_name, "current-school"))

      choose school.name
      click_button "Continue"

      expect(page).to have_text(leadership_position_question)
    end

    scenario "School search form still works like a normal form if submitted", js: true do
      start_student_loans_claim

      expect(page).to have_text(claim_school_question)
      expect(page).to have_button("Continue")

      question = page.find("h1").text
      fill_in question, with: search_keywords(school)
      expect(page).to have_text(school.name)
      click_button "Continue"

      choose school.name
      click_button "Continue"
    end

    scenario "Editing school search after autocompletion clears last selection", js: true, flaky: true do
      another_school = create(:school, :student_loans_eligible)
      start_student_loans_claim

      question = page.find("h1").text
      expect(page).to have_text(claim_school_question)
      fill_in question, with: search_keywords(school)
      sleep(1) # seems to aid in success, as if click happens before event is bound
      find("li", text: school.name).click
      fill_in question, with: search_keywords(another_school)
      sleep(1) # seems to aid in success, as if click happens before event is bound
      find("li", text: another_school.name).click
      click_button "Continue"

      choose another_school.name
      click_button "Continue"

      expect(page).to have_text("Which of the following subjects did you teach at #{another_school.name}")
    end

    context "with a closed school" do
      let!(:closed_school) { create(:school, :student_loans_eligible, :closed) }

      scenario "Claim school search includes closed schools" do
        start_student_loans_claim

        expect(page).to have_text(claim_school_question)
        expect(page).to have_button("Continue")

        question = page.find("h1").text
        fill_in question, with: search_keywords(closed_school)
        click_button "Continue"

        expect(page).to have_text(closed_school.name)
      end

      scenario "Current school search excludes closed schools" do
        start_student_loans_claim
        choose_school school
        choose_subjects_taught
        choose_still_teaching "Yes, at another school"

        expect(page).to have_text(I18n.t("student_loans.forms.current_school.question"))
        expect(page).to have_button("Continue")

        fill_in I18n.t("student_loans.forms.current_school.question"), with: search_keywords(closed_school)
        click_button "Continue"

        expect(page).not_to have_text(closed_school.name)
      end

      scenario "Claim school search with autocomplete includes closed schools", js: true do
        start_student_loans_claim

        expect(page).to have_text(claim_school_question)
        expect(page).to have_button("Continue")

        question = page.find("h1").text
        fill_in question, with: search_keywords(closed_school)
        expect(page).to have_text(closed_school.name)
      end

      scenario "Current school search with autocomplete excludes closed schools", js: true, flaky: true do
        start_student_loans_claim

        choose_school school
        choose_subjects_taught
        choose_still_teaching "Yes, at another school"

        expect(page).to have_text(I18n.t("student_loans.forms.current_school.question"))
        expect(page).to have_button("Continue")

        fill_in I18n.t("student_loans.forms.current_school.question"), with: search_keywords(closed_school)
        expect(page).not_to have_text(closed_school.name)
      end
    end
  end

  context "Targeted Retention Incentive journey claim" do
    before { create(:journey_configuration, :targeted_retention_incentive_payments) }
    let!(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
    let!(:closed_school) { create(:school, :targeted_retention_incentive_payments_eligible, :closed) }

    scenario "doesn't select a school from the search results the first time around" do
      visit new_claim_path(Journeys::TargetedRetentionIncentivePayments.routing_name)

      # - Check eligibility intro
      expect(page).to have_text("Check you’re eligible for a targeted retention incentive payment")
      click_on "Start eligibility check"

      # - Sign in or continue page
      expect(page).to have_text("Use DfE Identity to sign in")
      click_on "Continue without signing in"

      # Creates a duplicate school to test whether the school search shows closed schools
      duplicate_school = create(:school, :student_loans_eligible, :closed, name: "#{school.name} Duplicate")

      question = page.find("h1").text
      fill_in question, with: search_keywords(school)
      click_on "Continue"

      # Backlink is to the same slug as current (current-school)
      expect(page).to have_link("Back", href: claim_path(Journeys::TargetedRetentionIncentivePayments.routing_name, "current-school"))

      click_on "Continue"

      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Select the school you teach at")

      expect(page).to have_text(school.name)
      expect(page).not_to have_text(duplicate_school.name)
    end
  end
end
