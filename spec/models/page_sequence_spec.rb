# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { TslrClaim.new }

  describe "#slugs" do
    it "excludes “current-school” when the claimant still works at the school they are claiming against" do
      claim.employment_status = :claim_school
      page_sequence = PageSequence.new(claim, "still-teaching")

      expect(page_sequence.slugs).not_to include("current-school")
    end

    it "excludes student loan-related pages when the claimant no longer has a student loan" do
      claim.has_student_loan = false
      page_sequence = PageSequence.new(claim, "still-teaching")
      expect(page_sequence.slugs).not_to include("student-loan-country")
      expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")

      claim.has_student_loan = true
      page_sequence = PageSequence.new(claim, "still-teaching")
      expect(page_sequence.slugs).to include("student-loan-country")
      expect(page_sequence.slugs).to include("student-loan-how-many-courses")
    end

    it "excludes “student-loan-how-many-courses” when the claimant received their student loan in Scotland or Northern Ireland" do
      claim.has_student_loan = true

      TslrClaim::STUDENT_LOAN_COUNTRIES_WITH_ONE_PLAN.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        page_sequence = PageSequence.new(claim, "student-loan-country")
        expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        page_sequence = PageSequence.new(claim, "student-loan-country")
        expect(page_sequence.slugs).to include("student-loan-how-many-courses")
      end
    end
  end

  describe "#next_slug" do
    it "returns the next slug in the sequence" do
      expect(PageSequence.new(claim, "qts-year").next_slug).to eq "claim-school"
      expect(PageSequence.new(claim, "claim-school").next_slug).to eq "still-teaching"
    end

    context "with an ineligible claim" do
      let(:claim) { TslrClaim.new(employment_status: :no_school) }

      it "returns “ineligible” as the next slug" do
        expect(PageSequence.new(claim, "still-teaching").next_slug).to eq "ineligible"
      end
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:claim) { build(:tslr_claim, :submittable) }

      it "returns “check-your-answers” as the next slug" do
        expect(PageSequence.new(claim, "qts-year").next_slug).to eq "check-your-answers"
      end
    end
  end
end
