# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageSequence do
  let(:claim) { build(:claim) }
  let(:sequence_version) { 0 }

  describe ".all_slugs" do
    it "returns a list of all possible slugs in any order" do
      expect(PageSequence.all_slugs).to match_array([
        "qts-year",
        "claim-school",
        "still-teaching",
        "current-school",
        "subjects-taught",
        "leadership-position",
        "mostly-performed-leadership-duties",
        "eligibility-confirmed",
        "information-provided",
        "verified",
        "address",
        "gender",
        "teacher-reference-number",
        "national-insurance-number",
        "student-loan",
        "student-loan-country",
        "student-loan-how-many-courses",
        "student-loan-start-date",
        "student-loan-amount",
        "email-address",
        "bank-details",
        "check-your-answers",
        "confirmation",
        "ineligible",
      ])
    end
  end

  describe "#slugs" do
    it "only returns slugs in the given sequence" do
      stub_const("PageSequence::QUESTION_SLUGS", PageSequence::QUESTION_SLUGS.merge("test_version" => ["test-slug"]))

      page_sequence = PageSequence.new(claim, "qts-year", sequence_version: sequence_version)

      expect(PageSequence::QUESTION_SLUGS["test_version"]).to include("test-slug")
      expect(page_sequence.slugs).not_to include("test-slug")
    end

    it "excludes “current-school” when the claimant still works at the school they are claiming against" do
      claim.eligibility.employment_status = :claim_school
      page_sequence = PageSequence.new(claim, "still-teaching", sequence_version: sequence_version)

      expect(page_sequence.slugs).not_to include("current-school")
    end

    it "excludes student loan-related pages when the claimant no longer has a student loan" do
      claim.has_student_loan = false
      page_sequence = PageSequence.new(claim, "still-teaching", sequence_version: sequence_version)
      expect(page_sequence.slugs).not_to include("student-loan-country")
      expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(page_sequence.slugs).not_to include("student-loan-start-date")

      claim.has_student_loan = true
      page_sequence = PageSequence.new(claim, "still-teaching", sequence_version: sequence_version)
      expect(page_sequence.slugs).to include("student-loan-country")
      expect(page_sequence.slugs).to include("student-loan-how-many-courses")
      expect(page_sequence.slugs).to include("student-loan-start-date")
    end

    it "excludes the remaining student loan-related pages when the claimant received their student loan in Scotland or Northern Ireland" do
      claim.has_student_loan = true

      StudentLoans::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        page_sequence = PageSequence.new(claim, "student-loan-country", sequence_version: sequence_version)
        expect(page_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(page_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        page_sequence = PageSequence.new(claim, "student-loan-country", sequence_version: sequence_version)
        expect(page_sequence.slugs).to include("student-loan-how-many-courses")
        expect(page_sequence.slugs).to include("student-loan-start-date")
      end
    end

    it "excludes the gender page if a response has been returned from Verify" do
      claim.verified_fields = ["payroll_gender"]
      page_sequence = PageSequence.new(claim, "student-loan-country", sequence_version: sequence_version)
      expect(page_sequence.slugs).to_not include("gender")

      claim.verified_fields = []
      expect(page_sequence.slugs).to include("gender")
    end

    it "excludes the address page if the address was returned by verify" do
      claim.verified_fields = ["postcode"]
      page_sequence = PageSequence.new(claim, "student-loan-country", sequence_version: sequence_version)
      expect(page_sequence.slugs).to_not include("address")
    end
  end

  describe "#next_slug" do
    it "returns the next slug in the sequence" do
      expect(PageSequence.new(claim, "qts-year", sequence_version: sequence_version).next_slug).to eq "claim-school"

      claim.eligibility.qts_award_year = :"2013_2014"

      expect(PageSequence.new(claim, "claim-school", sequence_version: sequence_version).next_slug).to eq "still-teaching"
    end

    it "returns the slug of an unanswered question if the sequence has skipped one" do
      expect(PageSequence.new(claim, "claim-school", sequence_version: sequence_version).next_slug).to eq("qts-year")
    end

    it "returns the slug of an unanswered question if the sequence has reached the end" do
      expect(PageSequence.new(build(:claim, :submittable, email_address: nil), "check-your-answers", sequence_version: sequence_version).next_slug).to eq("email-address")
    end

    it "returns the slug of a question missing from the sequence if the sequence has reached the end and the claim is not submittable" do
      stub_const("PageSequence::QUESTION_SLUGS", {
        sequence_version => PageSequence::QUESTION_SLUGS[sequence_version] - ["email-address"],
        "new_version" => ["email-address"],
      })

      expect(PageSequence.new(build(:claim, :submittable, email_address: nil), "check-your-answers", sequence_version: sequence_version).next_slug).to eq("email-address")
    end

    context "with an ineligible claim" do
      let(:claim) { build(:claim, eligibility: build(:student_loans_eligibility, employment_status: :no_school)) }

      it "returns “ineligible” as the next slug" do
        expect(PageSequence.new(claim, "still-teaching", sequence_version: sequence_version).next_slug).to eq "ineligible"
      end
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:claim) { build(:claim, :submittable) }

      it "returns “check-your-answers” as the next slug" do
        expect(PageSequence.new(claim, "qts-year", sequence_version: sequence_version).next_slug).to eq "check-your-answers"
      end
    end
  end

  describe "in_sequence?" do
    let(:page_sequence) { PageSequence.new(claim, "gender", sequence_version: sequence_version) }

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
