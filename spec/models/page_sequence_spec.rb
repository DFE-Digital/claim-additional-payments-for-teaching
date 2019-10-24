# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { build(:claim) }

  describe "#next_slug" do
    it "assumes we're at the beginning of the sequence if no current_slug is specified" do
      expect(PageSequence.new(claim, nil).next_slug).to eq "claim-school"
    end

    it "returns the next slug in the sequence" do
      expect(PageSequence.new(claim, "qts-year").next_slug).to eq "claim-school"
      expect(PageSequence.new(claim, "claim-school").next_slug).to eq "still-teaching"
    end

    context "with an ineligible claim" do
      let(:claim) { build(:claim, eligibility: build(:student_loans_eligibility, employment_status: :no_school)) }

      it "returns “ineligible” as the next slug" do
        expect(PageSequence.new(claim, "still-teaching").next_slug).to eq "ineligible"
      end
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:claim) { build(:claim, :submittable) }

      it "returns “check-your-answers” as the next slug" do
        expect(PageSequence.new(claim, "qts-year").next_slug).to eq "check-your-answers"
      end
    end
  end

  describe "in_sequence?" do
    let(:page_sequence) { PageSequence.new(claim, "gender") }

    context "when the page is not in the sequence" do
      before do
        claim.verified_fields = ["payroll_gender"]
      end

      it { expect(page_sequence.in_sequence?("gender")).to eq(false) }
    end

    context "when the page is in the sequence" do
      before do
        claim.verified_fields = []
      end

      it { expect(page_sequence.in_sequence?("gender")).to eq(true) }
    end
  end
end
