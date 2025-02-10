require "rails_helper"

RSpec.feature "Ineligible Levelling up premium payments claims" do
  let(:eligibility) { Policies::LevellingUpPremiumPayments::Eligibility.order(:created_at).last }
  let(:journey_session) { Journeys::AdditionalPaymentsForTeaching::Session.last }

  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }

  scenario "When the school selected is LUP ineligible" do
    school = create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_ineligible)
    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be false

    choose_school school
    click_on "Continue"
    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be true

    expect(page).not_to have_text("The school you have selected is not eligible")
  end

  scenario "When the school selected is both ECP and LUP ineligible" do
    school = create(:school, :early_career_payments_ineligible, :levelling_up_premium_payments_ineligible)
    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be false
    choose_school school
    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be true

    expect(page).to have_text("The school you have selected is not eligible")
  end

  scenario "When subject 'none of the above' and user does not have an eligible degree" do
    school = create(:school, :levelling_up_premium_payments_eligible)

    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

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

    # - In which academic year did you complete your undergraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2018 to 2019"
    click_on "Continue"

    expect(page).to have_text("Which subject")
    choose "None of the above"
    click_on "Continue"

    # Do you have an undergraduate or postgraduate degree in an eligible subject?
    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))
    click_on "Continue"
    expect(page).to have_text("Select yes if you have a degree in an eligible subject")

    choose "No"

    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be false
    click_on "Continue"

    expect(
      eligibility_checker(journey_session).ineligible?
    ).to be true

    expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
    expect(page).to have_css("div#lack_both_valid_itt_subject_and_degree")

    # Check we can go back and change the answer
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "eligible-degree-subject")
    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/eligible-degree-subject")

    choose "Yes"
    click_on "Continue"

    expect(
      eligibility_checker(journey_session)
    ).not_to be_ineligible

    expect(page).to have_current_path("/#{Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME}/teaching-subject-now")
  end

  def eligibility_checker(journey_session)
    Policies::LevellingUpPremiumPayments::PolicyEligibilityChecker.new(
      answers: journey_session.reload.answers
    )
  end
end
