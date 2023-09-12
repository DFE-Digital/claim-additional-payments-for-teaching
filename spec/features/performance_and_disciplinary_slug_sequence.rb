require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims sequence slug" do
  include OmniauthMockHelper

  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(current_claim) }

  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:ecp_eligibility) { build(:early_career_payments_eligibility) }
  let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility) }

  let(:claim) { create(:claim, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
  let(:lup_claim) do
    build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility)
  end

  let!(:current_claim) { CurrentClaim.new(claims: [claim, lup_claim]) }

  before do
    set_mock_auth("1234567")
    allow_any_instance_of(PartOfClaimJourney).to receive(:current_claim).and_return(current_claim)
  end

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with teacher_id" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("You can use a DfE Identity account with this service")
    click_on "Sign in with teacher identity"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))

    choose_school school

    click_on "Continue"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

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

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false
  end
end
