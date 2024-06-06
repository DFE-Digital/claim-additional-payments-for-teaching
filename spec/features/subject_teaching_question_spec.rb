require "rails_helper"

RSpec.feature "Resetting dependant attributes when the claim is ineligible" do
  let(:claim) { start_early_career_payments_claim }
  let(:journey_session) { Journeys::AdditionalPaymentsForTeaching::Session.last }

  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

  before do
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible, :eligible_school_ecp_and_lup))
  end

  context "when ECP and LUP eligible" do
    it "has the correct subjects" do
      jump_to_claim_journey_page(
        claim: claim,
        slug: "nqt-in-academic-year-after-itt",
        journey_session: journey_session
      )
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "itt-year",
        journey_session: journey_session
      )
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "eligible-itt-subject",
        journey_session: journey_session
      )
      choose "Mathematics"
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "teaching-subject-now",
        journey_session: journey_session
      )
      expect(page).to have_text("chemistry, computing, languages, mathematics or physics")

      click_on "Continue"
      expect(page).to have_text("Select yes if you spend at least half of your contracted hours teaching eligible subjects")
    end
  end

  context "when eligible only for ECP" do
    it "has the correct subjects" do
      jump_to_claim_journey_page(
        claim: claim,
        slug: "nqt-in-academic-year-after-itt",
        journey_session: journey_session
      )
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "itt-year",
        journey_session: journey_session
      )
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "eligible-itt-subject",
        journey_session: journey_session
      )
      choose "Languages" # ECP-only subject
      click_on "Continue"

      jump_to_claim_journey_page(
        claim: claim,
        slug: "teaching-subject-now",
        journey_session: journey_session
      )
      expect(page).to have_text("chemistry, languages, mathematics or physics.")
    end
  end

  context "when eligible only for LUP" do
    before do
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :ineligible))
    end

    it "has the correct subjects" do
      jump_to_claim_journey_page(
        claim: claim,
        slug: "teaching-subject-now",
        journey_session: journey_session
      )

      expect(page).to have_text("chemistry, computing, mathematics or physics")
    end
  end
end
