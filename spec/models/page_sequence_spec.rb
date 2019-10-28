# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { build(:claim) }
  let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "second-slug", "third-slug"]) }

  describe "#next_slug" do
    it "assumes we're at the beginning of the sequence if no current_slug is specified" do
      expect(PageSequence.new(claim, slug_sequence, nil).next_slug).to eq "second-slug"
    end

    it "returns the next slug in the sequence" do
      expect(PageSequence.new(claim, slug_sequence, "first-slug").next_slug).to eq "second-slug"
      expect(PageSequence.new(claim, slug_sequence, "second-slug").next_slug).to eq "third-slug"
    end

    context "with an ineligible claim" do
      let(:claim) { build(:claim, eligibility: build(:student_loans_eligibility, employment_status: :no_school)) }

      it "returns “ineligible” as the next slug" do
        expect(PageSequence.new(claim, slug_sequence, ["second-slug"]).next_slug).to eq "ineligible"
      end
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:claim) { build(:claim, :submittable) }

      it "returns “check-your-answers” as the next slug" do
        expect(PageSequence.new(claim, slug_sequence, ["third-slug"]).next_slug).to eq "check-your-answers"
      end
    end
  end

  describe "in_sequence?" do
    let(:page_sequence) { PageSequence.new(claim, slug_sequence, ["third-slug"]) }

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
