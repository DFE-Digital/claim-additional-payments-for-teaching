require "rails_helper"

RSpec.feature "Early-Career Payments claims with school ineligible for Levelling-Up Premium Payment" do
  include EarlyCareerPaymentsHelper

  # create a school eligible for ECP and ineligible LUPP
  let!(:school) { create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_ineligible) }
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let(:current_academic_year) { policy_configuration.current_academic_year }

  let(:itt_year) do
    case current_academic_year
    when 2023 then AcademicYear.new(2018)
    else AcademicYear.new(2019)
    end
  end

  scenario "where only Mathematics is a valid ITT subject option", js: true do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    click_on "Start now"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Performance Issues
    expect(page).to have_text(I18n.t("early_career_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"

    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "#{itt_year.start_year} to #{itt_year.end_year}"
    click_on "Continue"

    expect(page).to have_text("Did you do your undergraduate initial teacher training (ITT) in mathematics?")

    expect(page).not_to have_text("If you qualified with science")

    choose "Yes"
    click_on "Continue"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("Based on what you told us, you can apply for an early-career payment of:\n£7,500")
  end
end
