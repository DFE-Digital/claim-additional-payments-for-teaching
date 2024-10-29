# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::Eligibility, type: :model do
  describe "#policy" do
    let(:early_career_payments_eligibility) { build(:early_career_payments_eligibility) }

    it "has a policy class of 'EarlyCareerPayments'" do
      expect(early_career_payments_eligibility.policy).to eq Policies::EarlyCareerPayments
    end
  end

  describe "correct-school submit" do
    let(:school) { create(:school, :early_career_payments_eligible) }

    context "current_school not set and school_somewhere_else is not set return one is required error" do
      it "returns an error" do
        eligibility = Policies::EarlyCareerPayments::Eligibility.new(current_school: nil, school_somewhere_else: nil)

        expect(eligibility).not_to be_valid(:"correct-school")
        expect(eligibility.errors.messages[:current_school]).to eq(["Select the school you teach at or choose somewhere else"])
      end
    end

    context "selects a school suggested from TPS" do
      it "sets current_school and sets school_somewhere_else to false" do
        eligibility = Policies::EarlyCareerPayments::Eligibility.new(current_school: school, school_somewhere_else: false)

        expect(eligibility).to be_valid(:"correct-school")
      end
    end

    context "selects somewhere else and not the suggested school" do
      it "sets school_somewhere_else to true and current_school stays nil" do
        eligibility = Policies::EarlyCareerPayments::Eligibility.new(current_school: nil, school_somewhere_else: true)

        expect(eligibility).to be_valid(:"correct-school")
      end

      # e.g. the teacher presses the backlink a school is already set
      it "sets school_somewhere_else to true and current_school stays remains if already set" do
        eligibility = Policies::EarlyCareerPayments::Eligibility.new(current_school: school, school_somewhere_else: true)

        expect(eligibility).to be_valid(:"correct-school")
      end
    end
  end

  describe "qualification attribute" do
    it "rejects invalid values" do
      expect { Policies::EarlyCareerPayments::Eligibility.new(qualification: "non-existance") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = Policies::EarlyCareerPayments::Eligibility.new(qualification: "postgraduate_itt")

      expect(eligibility.postgraduate_itt?).to eq true
      expect(eligibility.undergraduate_itt?).to eq false
      expect(eligibility.assessment_only?).to eq false
      expect(eligibility.overseas_recognition?).to eq false
    end
  end

  describe "eligible_itt_subject attribute" do
    it "rejects invalid values" do
      expect { Policies::EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "not-in-list-of-options") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = Policies::EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "foreign_languages")

      expect(eligibility.itt_subject_foreign_languages?).to eq true
      expect(eligibility.itt_subject_chemistry?).to eq false
      expect(eligibility.itt_subject_mathematics?).to eq false
      expect(eligibility.itt_subject_physics?).to eq false
      expect(eligibility.itt_subject_none_of_the_above?).to eq false
    end
  end

  describe "#award_amount" do
    context "amendment" do
      it { should_not allow_values(0, nil).for(:award_amount).on(:amendment) }
      it { should validate_numericality_of(:award_amount).on(:amendment).is_greater_than(0).is_less_than_or_equal_to(7_500).with_message("Enter a positive amount up to £7,500.00 (inclusive)") }
    end

    context "with a value of 1_000" do
      let(:eligibility) do
        create(
          :early_career_payments_eligibility,
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
          eligible_itt_subject: :mathematics,
          award_amount: 1_000
        )
      end

      it "returns the correct value" do
        expect(eligibility.award_amount).to eql 1_000
      end
    end
  end

  describe "validation contexts" do
    context "award_amount attribute" do
      it "validates the award_amount is numerical" do
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: "don't know")).not_to be_valid
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: "£2,000.00")).not_to be_valid
      end

      it "validates that award_amount is a positive number" do
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: -1_000)).not_to be_valid
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: 2_500)).to be_valid
      end

      it "validates that award_amount can be zero" do
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: 0)).to be_valid
      end

      it "validates that the award_amount is less than £7,500 when amending a claim" do
        expect(Policies::EarlyCareerPayments::Eligibility.new(teacher_reference_number: "1234567", award_amount: 7_501)).not_to be_valid(:amendment)
        expect(Policies::EarlyCareerPayments::Eligibility.new(teacher_reference_number: "1234567", award_amount: 7_500)).to be_valid(:amendment)
        expect(Policies::EarlyCareerPayments::Eligibility.new(teacher_reference_number: "1234567", award_amount: 7_499)).to be_valid(:amendment)
      end
    end
  end

  describe ".max_award_amount_in_pounds" do
    specify { expect(described_class.max_award_amount_in_pounds).to eq(7_500) }
  end
end
