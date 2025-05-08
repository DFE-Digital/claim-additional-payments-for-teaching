require "rails_helper"

RSpec.feature "ITT subject selection", slow: true do
  before { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: AcademicYear.new(2022)) }

  # Note: If we ever change the UI to show all the options in all cases,
  # you *should* choose a subject instead of "None of the above" in the specs below.
  # Also in that case there's no point in asserting the displayed subject options
  # because they will always be the same.
  context "year and subject options" do
    before do
      navigate_to_year_selection(school)
      select_itt_year(itt_year)
    end

    context "Targeted Retention Incentive school" do
      let!(:school) { create(:school, :early_career_payments_eligible, :targeted_retention_incentive_payments_eligible) }

      context "ITT year 2017" do
        let(:itt_year) { AcademicYear.new(2017) }

        scenario "handles eligible and ineligible subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text("Do you have a degree in an eligible subject?")
        end
      end

      context "ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        scenario "handles eligible and ineligible subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text("Do you have a degree in an eligible subject?")
        end
      end

      context "ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          # choose subject eligible for Targeted Retention Incentive only
          select_subject("Chemistry")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          # choose subject eligible for both Targeted Retention Incentive and ECP
          select_subject("Mathematics")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          # choose ineligible subject for both ECP and Targeted Retention Incentive
          select_subject("None of the above")
          expect(page).to have_text("Do you have a degree in an eligible subject?")
        end
      end

      context "ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          # choose eligible subject
          select_subject("Mathematics")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          # choose none of the above
          select_subject("None of the above")
          expect(page).to have_text("Do you have a degree in an eligible subject?")
        end
      end

      context "ITT year 2021" do
        let(:itt_year) { AcademicYear.new(2021) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text("Do you have a degree in an eligible subject?")
        end
      end
    end
  end

  private

  def navigate_to_year_selection(school)
    start_targeted_retention_incentive_payments_claim
    skip_tid

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text("Are you currently teaching as a qualified teacher?")

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text("Are you currently employed as a supply teacher?")

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text("Are you subject to any formal performance measures as a result of continuous poor teaching standards?")
    expect(page).to have_text("Are you currently subject to disciplinary action?")

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text("Which route into teaching did you take?")

    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"
  end

  def select_itt_year(year)
    year_string = "#{year.start_year} to #{year.end_year}"
    choose year_string
    click_on "Continue"
  end

  def select_subject(subject_string)
    choose subject_string
    click_on "Continue"
  end

  def expect_displayed_subjects(displayed_subject_display_strings)
    if displayed_subject_display_strings.one?
      question_text = find("h1.govuk-fieldset__heading").text
      expect(question_text).to include(displayed_subject_display_strings.first.downcase)
    else
      displayed_subject_display_strings.each do |subject_display_string|
        expect(page).to have_field(subject_display_string)
      end

      entire_set_of_targeted_retention_incentive_and_ecp_subject_display_strings = ["Chemistry", "Computing", "Languages", "Mathematics", "Physics"]
      missing_subject_display_strings = entire_set_of_targeted_retention_incentive_and_ecp_subject_display_strings - displayed_subject_display_strings

      missing_subject_display_strings.each do |missing_subject_display_string|
        expect(page).to have_no_field(missing_subject_display_string)
      end
    end
  end
end
