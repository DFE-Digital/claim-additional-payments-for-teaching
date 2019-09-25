# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { build(:claim) }

  describe "#slugs" do
    it "excludes “current-school” if and only if the claimant still works at the school they are claiming against" do
      page_sequence = PageSequence.new(claim, "still-teaching")

      claim.eligibility.employment_status = :different_school
      expect(page_sequence.slugs).to include("current-school")

      claim.eligibility.employment_status = :claim_school
      expect(page_sequence.slugs).not_to include("current-school")
    end

    it "excludes student loan related pages if and only if the claimant no longer has a student loan" do
      page_sequence = PageSequence.new(claim, "still-teaching")

      claim.has_student_loan = false
      expect(page_sequence.slugs).not_to include("student-loan-country")
      expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(page_sequence.slugs).not_to include("student-loan-start-date")

      claim.has_student_loan = true
      expect(page_sequence.slugs).to include("student-loan-country")
      expect(page_sequence.slugs).to include("student-loan-how-many-courses")
      expect(page_sequence.slugs).to include("student-loan-start-date")
    end

    it "excludes the remaining student loan-related pages if and only if the claimant received their student loan in Scotland or Northern Ireland" do
      page_sequence = PageSequence.new(claim, "student-loan-country")

      claim.has_student_loan = true

      StudentLoans::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(page_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        expect(page_sequence.slugs).to include("student-loan-how-many-courses")
        expect(page_sequence.slugs).to include("student-loan-start-date")
      end
    end

    it "excludes the gender page if and only if a response has been returned from Verify" do
      page_sequence = PageSequence.new(claim, "student-loan-country")

      claim.verified_fields = []
      expect(page_sequence.slugs).to include("gender")

      claim.verified_fields = ["payroll_gender"]
      expect(page_sequence.slugs).to_not include("gender")
    end

    it "excludes the address page if and only if the address was returned by verify" do
      page_sequence = PageSequence.new(claim, "student-loan-country")

      claim.verified_fields = []
      expect(page_sequence.slugs).to include("address")

      claim.verified_fields = ["postcode"]
      expect(page_sequence.slugs).to_not include("address")
    end
  end

  describe "#next_slug" do
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
