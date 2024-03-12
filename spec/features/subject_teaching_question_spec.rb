require "rails_helper"

RSpec.feature "Resetting dependant attributes when the claim is ineligible" do
  let(:claim) { start_early_career_payments_claim }

  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

  before do
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible, :eligible_school_ecp_and_lup))
  end

  context "when ECP and LUP eligible" do
    it "has the correct subjects" do
      jump_to_claim_journey_page(claim, "nqt-in-academic-year-after-itt")
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(claim, "itt-year")
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(claim, "eligible-itt-subject")
      choose "Mathematics"
      click_on "Continue"

      jump_to_claim_journey_page(claim, "teaching-subject-now")
      expect(page).to have_text("chemistry, computing, languages, mathematics or physics")

      click_on "Continue"
      expect(page).to have_text("Select yes if you spend at least half of your contracted hours teaching eligible subjects")
    end
  end

  context "when eligible only for ECP" do
    it "has the correct subjects" do
      jump_to_claim_journey_page(claim, "nqt-in-academic-year-after-itt")
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(claim, "itt-year")
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(claim, "eligible-itt-subject")
      choose "Languages" # ECP-only subject
      click_on "Continue"

      jump_to_claim_journey_page(claim, "teaching-subject-now")
      expect(page).to have_text("chemistry, languages, mathematics or physics.")
    end
  end

  context "when eligible only for LUP" do
    before do
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :ineligible))
    end

    it "has the correct subjects" do
      jump_to_claim_journey_page(claim, "teaching-subject-now")

      expect(page).to have_text("chemistry, computing, mathematics or physics")
    end
  end
end
