require "rails_helper"

RSpec.feature "Ineligible Teacher Early-Career Payments claims", slow: true do
  include EarlyCareerPaymentsHelper

  let!(:eligible_school) { create(:school, :early_career_payments_eligible) }

  before { create(:policy_configuration, :additional_payments) }

  scenario "When the school selected is ineligible" do
    ineligible_school = create(:school, :early_career_payments_ineligible)
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    choose_school ineligible_school

    expect(page).to have_text("The school you have selected is not eligible")
  end

  scenario "when poor performance - subject to formal performance action" do
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end

  scenario "when poor performance - subject to disciplinary action" do
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

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
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end

  scenario "when poor performance - subject to disciplinary & formal performance action" do
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end

  # Employed as Supply Teacher with contract less than an entire term
  scenario "supply teacher doesn't have a contract for a whole term at same school" do
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end

  # Employed as Supply Teacher by Private Agency
  scenario "Supply Teacher employed directly by Private Agency" do
    start_early_career_payments_claim

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    # - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end

  scenario "when subject for undergraduate ITT or postgraduate ITT is 'none of the above'" do
    start_early_career_payments_claim
    claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

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

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - In which academic year did you complete your undergraduate ITT?
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "2018 to 2019"
    click_on "Continue"

    expect(page).to have_text("Did you do your undergraduate initial teacher training (ITT) in mathematics?")

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "none_of_the_above"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#bad_itt_year_for_ecp")
  end

  scenario "when no longer teaching an eligible ITT subject" do
    start_early_career_payments_claim
    claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    ecp_only_school = eligible_school
    choose_school ecp_only_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

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

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "2020 to 2021"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # - Do you teach the eligible ITT subject now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql false

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#would_be_eligible_for_ecp_only_except_for_insufficient_teaching")
  end

  scenario "when academic year completed undergraduate ITT or started postgraduate ITT is 'none of the above'" do
    start_early_career_payments_claim
    claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last

    skip_tid

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school eligible_school

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("early_career_payments.questions.induction_completed.heading"))

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

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - In which academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "None of the above"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql AcademicYear.new

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_css("div#generic")
  end
end
