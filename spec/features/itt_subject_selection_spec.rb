require "rails_helper"

RSpec.feature "ITT subject selection" do
  let(:lup_school) { schools(:hampstead_school) }
  let(:ecp_only_school) { schools(:penistone_grammar_school) }

  # Note: If we ever change the UI to show all the options in all cases,
  # you *should* choose a subject instead of "None of the above" in the specs below.
  # Also in that case there's no point in asserting the displayed subject options
  # because they will always be the same.
  context "year and subject options" do
    before do
      navigate_to_year_selection(school)
      select_itt_year(itt_year)
    end

    context "LUP school" do
      let(:school) { lup_school }

      context "ITT year 2017" do
        let(:itt_year) { AcademicYear.new(2017) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
        end

        scenario "choose ineligible subject for both ECP and LUP" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
        end

        scenario "choose subject eligible for LUP only" do
          select_subject("Chemistry")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end

        scenario "choose subject eligible for both LUP and ECP" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Languages", "Mathematics", "Physics"])
        end

        scenario "choose none of the above" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
        end

        scenario "choose subject ineligible for LUP" do
          select_subject("Languages")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2021" do
        let(:itt_year) { AcademicYear.new(2021) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Computing", "Mathematics", "Physics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end
    end

    context "ECP-only school" do
      let(:school) { ecp_only_school }

      context "ITT year 2017" do
        let(:itt_year) { AcademicYear.new(2017) }

        scenario "no subject options" do
          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end
      end

      context "ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        scenario "subject options" do
          expect_displayed_subjects(["Mathematics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end

        scenario "choose eligible subject and teach now" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

          choose "Yes"
          click_on "Continue"

          click_on "Continue"

          expect(page).to have_text("you could claim for an early-career payment in the 2023 to 2024 academic year")
        end

        scenario "choose eligible subject but don't teach now" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

          choose "No"
          click_on "Continue"

          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end
      end

      context "ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        scenario "subject options" do
          expect_displayed_subjects(["Mathematics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        scenario "subject options" do
          expect_displayed_subjects(["Chemistry", "Languages", "Mathematics", "Physics"])
        end

        scenario "choose ineligible subject" do
          select_subject("None of the above")
          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end

        scenario "choose eligible subject" do
          select_subject("Mathematics")
          expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))
        end
      end

      context "ITT year 2021" do
        let(:itt_year) { AcademicYear.new(2021) }

        scenario "no subject options" do
          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
        end
      end
    end
  end

  private

  def navigate_to_year_selection(school)
    start_levelling_up_premium_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

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
    displayed_subject_display_strings.each do |subject_display_string|
      expect(page).to have_field(subject_display_string)
    end

    entire_set_of_lup_and_ecp_subject_display_strings = ["Chemistry", "Computing", "Languages", "Mathematics", "Physics"]
    missing_subject_display_strings = entire_set_of_lup_and_ecp_subject_display_strings - displayed_subject_display_strings

    missing_subject_display_strings.each do |missing_subject_display_string|
      expect(page).to have_no_field(missing_subject_display_string)
    end
  end
end
