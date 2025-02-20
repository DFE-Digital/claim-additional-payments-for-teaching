require "rails_helper"

RSpec.feature "ITT subject selection", slow: true do
  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

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
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
        end
      end

      context "ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        scenario "handles eligible and ineligible subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
        end
      end

      context "ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          # choose subject eligible for Targeted Retention Incentive only
          select_subject("Chemistry")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          # choose subject eligible for both Targeted Retention Incentive and ECP
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          # choose ineligible subject for both ECP and Targeted Retention Incentive
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
        end
      end

      context "ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Languages", "Mathematics", "Physics"])
          # choose subject ineligible for Targeted Retention Incentive
          select_subject("Languages")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          # choose eligible subject
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          # choose none of the above
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
        end
      end

      context "ITT year 2021" do
        let(:itt_year) { AcademicYear.new(2021) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
        end
      end
    end

    context "ECP-only school" do
      let!(:school) { create(:school, :early_career_payments_eligible, :targeted_retention_incentive_payments_ineligible) }

      context "ITT year 2017" do
        let(:itt_year) { AcademicYear.new(2017) }

        scenario "no subject options" do
          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end
      end

      context "ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        scenario "subject options" do
          expect_displayed_subjects(["Mathematics"])
        end

        scenario "choose ineligible subject" do
          select_subject("No")
          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end

        scenario "choose eligible subject and teach now" do
          select_subject("Yes")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

          choose "Yes"
          click_on "Continue"

          click_on "Continue"

          expect(page).to have_text("you could claim for an early-career payment in the 2023 to 2024 academic year")
        end

        scenario "choose eligible subject but don't teach now" do
          select_subject("Yes")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

          choose "No"
          click_on "Continue"

          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end
      end

      context "ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        scenario "subject options" do
          expect_displayed_subjects(["Mathematics"])
          select_subject("Yes")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          select_subject("No")
          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end
      end

      context "ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Languages", "Mathematics", "Physics"])
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))
          click_link "Back"
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end
      end

      context "ITT year 2021" do
        let(:itt_year) { AcademicYear.new(2021) }

        scenario "no subject options" do
          expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
        end
      end
    end
  end

  private

  def navigate_to_year_selection(school)
    start_targeted_retention_incentive_payments_claim
    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.question"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

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
