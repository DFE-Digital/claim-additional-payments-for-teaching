require "rails_helper"

RSpec.describe Claims::Match do
  describe "validations" do
    describe "match_is_from_previous_year" do
      context "when the matching claim is from the previous academic year" do
        it "does not add an error" do
          source_claim = build(:claim, academic_year: AcademicYear.new(2025))

          matching_claim = build(:claim, academic_year: AcademicYear.new(2024))

          match = described_class.new(
            source_claim: source_claim,
            matching_claim: matching_claim
          )

          expect(match.valid?).to be true
        end
      end

      context "when the matching claim is not from the previous academic year" do
        it "adds an error" do
          source_claim = build(:claim, academic_year: AcademicYear.new(2025))

          matching_claim = build(:claim, academic_year: AcademicYear.new(2025))

          match = described_class.new(
            source_claim: source_claim,
            matching_claim: matching_claim
          )

          expect(match.valid?).to be false

          expect(match.errors[:matching_claim]).to include(
            "must be from the previous academic year"
          )
        end
      end
    end
  end
end
