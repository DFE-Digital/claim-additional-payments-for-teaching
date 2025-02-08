require "rails_helper"

RSpec.feature "Resetting dependant attributes when the claim is ineligible" do
  let(:journey_session) { Journeys::AdditionalPaymentsForTeaching::Session.last }

  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

  before do
    start_early_career_payments_claim
    journey_session.answers.assign_attributes(
      attributes_for(
        :additional_payments_answers,
        :ecp_eligible,
        :eligible_school_ecp_and_targeted_retention_incentive,
        teaching_subject_now: nil # temp until the form that resets this is migrated to reset answers
      )
    )
    journey_session.save!
  end

  context "when ECP and Targeted Retention Incentive eligible" do
    it "has the correct subjects" do
      jump_to_claim_journey_page(
        slug: "nqt-in-academic-year-after-itt",
        journey_session: journey_session
      )
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(
        slug: "itt-year",
        journey_session: journey_session
      )
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(
        slug: "eligible-itt-subject",
        journey_session: journey_session
      )
      choose "Mathematics"
      click_on "Continue"

      jump_to_claim_journey_page(
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
        slug: "nqt-in-academic-year-after-itt",
        journey_session: journey_session
      )
      choose "Yes"
      click_on "Continue"

      jump_to_claim_journey_page(
        slug: "itt-year",
        journey_session: journey_session
      )
      choose "2020 to 2021"
      click_on "Continue"

      jump_to_claim_journey_page(
        slug: "eligible-itt-subject",
        journey_session: journey_session
      )
      choose "Languages" # ECP-only subject
      click_on "Continue"

      jump_to_claim_journey_page(
        slug: "teaching-subject-now",
        journey_session: journey_session
      )
      expect(page).to have_text("chemistry, languages, mathematics or physics.")
    end
  end

  context "when eligible only for Targeted Retention Incentive" do
    before do
      journey_session.answers.assign_attributes(
        attributes_for(
          :additional_payments_answers,
          :ecp_ineligible,
          :targeted_retention_incentive_eligible
        )
      )
      journey_session.save!
    end

    it "has the correct subjects" do
      jump_to_claim_journey_page(
        slug: "teaching-subject-now",
        journey_session: journey_session
      )

      expect(page).to have_text("chemistry, computing, mathematics or physics")
    end
  end
end
