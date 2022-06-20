# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { build(:claim) }
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }
  let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "second-slug", "third-slug"]) }

  describe "#next_slug" do
    it "assumes we're at the beginning of the sequence if no current_slug is specified" do
      expect(PageSequence.new(current_claim, slug_sequence, nil).next_slug).to eq "second-slug"
    end

    it "returns the next slug in the sequence" do
      expect(PageSequence.new(current_claim, slug_sequence, "first-slug").next_slug).to eq "second-slug"
      expect(PageSequence.new(current_claim, slug_sequence, "second-slug").next_slug).to eq "third-slug"
    end

    context "with an ineligible claim" do
      let(:claim) { build(:claim, eligibility: build(:student_loans_eligibility, employment_status: :no_school)) }

      it "returns “ineligible” as the next slug" do
        expect(PageSequence.new(current_claim, slug_sequence, ["second-slug"]).next_slug).to eq "ineligible"
      end
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:claim) { build(:claim, :submittable) }

      it "returns “check-your-answers” as the next slug" do
        expect(PageSequence.new(current_claim, slug_sequence, ["third-slug"]).next_slug).to eq "check-your-answers"
      end
    end

    context "when address is populated from 'select-home-address'" do
      [
        {policy: EarlyCareerPayments, next_slug: "email-address", slug_sequence: OpenStruct.new(slugs: ["postcode-search", "select-home-address", "address", "email-address"])},
        {policy: MathsAndPhysics, next_slug: "date-of-birth", slug_sequence: OpenStruct.new(slugs: ["postcode-search", "select-home-address", "address", "date-of-birth"])},
        {policy: StudentLoans, next_slug: "date-of-birth", slug_sequence: OpenStruct.new(slugs: ["postcode-search", "select-home-address", "address", "date-of-birth"])}
      ].each do |scenario|
        let(:claim) { build(:claim, policy: scenario[:policy]) }

        scenario "with #{scenario[:policy]} policy returns #{scenario[:next_slug]} as the next slug (NOT 'address')" do
          expect(PageSequence.new(current_claim, scenario[:slug_sequence], "address").next_slug).to eq scenario[:next_slug]
        end
      end
    end
  end

  describe "previous_slug" do
    context "first slug in wizard" do
      specify { expect(PageSequence.new(current_claim, slug_sequence, "first-slug").previous_slug).to be_nil }
    end

    context "second slug in wizard" do
      specify { expect(PageSequence.new(current_claim, slug_sequence, "second-slug").previous_slug).to eq("first-slug") }
    end

    context "third slug in wizard" do
      specify { expect(PageSequence.new(current_claim, slug_sequence, "third-slug").previous_slug).to eq("second-slug") }
    end

    context "dead ends" do
      let(:slug_sequence_with_dead_ends) { OpenStruct.new(slugs: ["first-slug", "complete", "existing-session", "eligible-now", "eligibility-confirmed", "eligible-later", "ineligible"]) }

      specify { expect(PageSequence.new(current_claim, slug_sequence_with_dead_ends, "complete").previous_slug).to be_nil }
      specify { expect(PageSequence.new(current_claim, slug_sequence_with_dead_ends, "existing-session").previous_slug).to be_nil }
      specify { expect(PageSequence.new(current_claim, slug_sequence_with_dead_ends, "eligible-now").previous_slug).to be_nil }
      specify { expect(PageSequence.new(current_claim, slug_sequence_with_dead_ends, "eligible-later").previous_slug).to be_nil }
      specify { expect(PageSequence.new(current_claim, slug_sequence_with_dead_ends, "ineligible").previous_slug).to be_nil }
    end
  end

  describe "in_sequence?" do
    let(:page_sequence) { PageSequence.new(current_claim, slug_sequence, "third-slug") }

    it "returns true when the slug is part of the sequence" do
      expect(page_sequence.in_sequence?("first-slug")).to eq(true)
      expect(page_sequence.in_sequence?("second-slug")).to eq(true)
    end

    it "returns false when the slug is not part of the sequence" do
      expect(page_sequence.in_sequence?("random-slug")).to eq(false)
      expect(page_sequence.in_sequence?("another-rando-slug")).to eq(false)
    end
  end
end
