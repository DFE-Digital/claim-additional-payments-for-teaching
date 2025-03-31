require "rails_helper"

RSpec.feature "Early-Career Payments claims with school ineligible for targeted_retention_incentive Payment" do
  include AdditionalPaymentsHelper

  # create a school eligible for ECP and ineligible Targeted Retention Incentive
  let!(:school) { create(:school, :early_career_payments_eligible, :targeted_retention_incentive_payments_ineligible) }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }
  let(:current_academic_year) { journey_configuration.current_academic_year }

  let(:itt_year) do
    case current_academic_year
    when 2023 then AcademicYear.new(2018)
    else AcademicYear.new(2019)
    end
  end

  scenario "where only Mathematics is a valid ITT subject option" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    click_on "Start now"

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
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

    # - Performance Issues
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.heading"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.performance.hint"))

    within all(".govuk-fieldset")[0] do
      choose("No")
    end

    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.question"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary.hint"))

    within all(".govuk-fieldset")[1] do
      choose("No")
    end

    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    session = Journeys::AdditionalPaymentsForTeaching::Session.last
    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{session.answers.qualification}"))

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Did you do your undergraduate initial teacher training (ITT) in mathematics?")

    expect(page).not_to have_text("If you qualified with science")

    choose "Yes"
    click_on "Continue"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("Based on what you told us, you can apply for an early-career payment of:\n£5,000")
  end
end
