require "rails_helper"

RSpec.feature "Resetting dependant attributes when the claim is ineligible" do
  let(:claim) { start_early_career_payments_claim }

  before { create(:policy_configuration, :additional_payments) }

  before do
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
  end

  context "when ECP and LUP eligible" do
    it "has the correct subjects" do
      visit claim_path(claim.policy.routing_name, "nqt-in-academic-year-after-itt")
      choose "Yes"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "itt-year")
      choose "2020 to 2021"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "eligible-itt-subject")
      choose "Mathematics"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "teaching-subject-now")
      expect(page).to have_text("chemistry, computing, languages, mathematics or physics")

      click_on "Continue"
      expect(page).to have_text("Select yes if you spend at least half of your contracted hours teaching eligible subjects")
    end
  end

  context "when eligible only for ECP" do
    let!(:school) { create(:school, :early_career_payments_eligible) }

    before do
      claim.eligibility.update!(itt_academic_year: AcademicYear.new(2020))
    end

    it "has the correct subjects" do
      visit claim_path(claim.policy.routing_name, "current-school")
      choose_school school

      visit claim_path(claim.policy.routing_name, "nqt-in-academic-year-after-itt")
      choose "Yes"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "itt-year")
      choose "2020 to 2021"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "eligible-itt-subject")
      choose "Mathematics"
      click_on "Continue"

      visit claim_path(claim.policy.routing_name, "teaching-subject-now")
      expect(page).to have_text("chemistry, languages, mathematics or physics.")
    end
  end

  context "when eligible only for LUP" do
    before do
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :ineligible))
    end

    it "has the correct subjects" do
      visit claim_path(claim.policy.routing_name, "teaching-subject-now")

      expect(page).to have_text("chemistry, computing, mathematics or physics")
    end
  end
end
