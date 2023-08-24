require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims sequence slug" do
  include OmniauthMockHelper
  include DqtApiHelper

  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(current_claim) }
  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { policy_configuration.current_academic_year }
  let(:ecp_eligibility) { build(:early_career_payments_eligibility) }
  let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility) }

  let(:itt_year) { current_academic_year - 3 }
  let(:claim) { create(:claim, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
  let(:lup_claim) do
    build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility)
  end

  let!(:current_claim) { CurrentClaim.new(claims: [claim, lup_claim]) }

  before do
    set_mock_auth("1234567")

    stub_dqt_request("1234567", "1993-07-25")

    allow_any_instance_of(PartOfClaimJourney).to receive(:current_claim).and_return(current_claim)

    allow(NotifySmsMessage).to receive(:new).with(
      phone_number: "07123456789",
      template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
      personalisation: {
        otp: "097543"
      }
    ).and_return(notify)
    allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator",
      code: "097543"))
    allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator",
      valid?: true))
  end

  after do
    set_mock_auth(nil)
  end

  scenario "When user is logged in with teacher_id and dqt api returns the teacher qualification data" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Which school do you teach at

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

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

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

    # It removes qualification questions from user journey
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now"))

    expect(current_claim.logged_in_with_tid).to eq(true)
    expect(current_claim.eligibility.qualification).to eq("postgraduate_itt")
    expect(current_claim.eligibility.eligible_itt_subject).to eq("mathematics")
    expect(current_claim.eligibility.itt_academic_year).to eq(AcademicYear.new(2021))
  end
end
