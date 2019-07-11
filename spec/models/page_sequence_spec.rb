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

      context "but they are updating their claim_school" do
        it "returns the next slug in the schools sequence" do
          expect(PageSequence.new(claim, "claim-school").next_slug).to eq "still-teaching"
        end
      end

      context "they’ve specified they’re still teaching at their claim school" do
        before { claim.employment_status = :claim_school }

        it "returns “check-your-answers” as the next slug (i.e. skips the current-school question)" do
          expect(PageSequence.new(claim, "still-teaching").next_slug).to eq "check-your-answers"
        end
      end

      context "they’ve specified they’re teaching at a different school" do
        before { claim.employment_status = :different_school }

        it "returns the final slug in the schools sequence" do
          expect(PageSequence.new(claim, "still-teaching").next_slug).to eq "current-school"
        end
      end
    end
  end
end
