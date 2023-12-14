# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::StudentLoans::Eligibility, type: :model do
  let(:eligible_school) { build(:school, :student_loans_eligible) }
  let(:ineligible_school) { build(:school, :student_loans_ineligible) }

  describe "qts_award_year attribute" do
    it "rejects invalid values" do
      expect { described_class.new(qts_award_year: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = described_class.new(qts_award_year: "on_or_after_cut_off_date")

      expect(eligibility.awarded_qualified_status_on_or_after_cut_off_date?).to eq true
      expect(eligibility.awarded_qualified_status_before_cut_off_date?).to eq false
    end
  end

  describe "employment_status attribute" do
    it "rejects invalid values" do
      expect { described_class.new(employment_status: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = described_class.new(employment_status: :claim_school)

      expect(eligibility.employed_at_claim_school?).to eq true
      expect(eligibility.employed_at_different_school?).to eq false
    end
  end

  describe "student_loan_repayment_amount attribute" do
    it "validates that the loan repayment amount is numerical" do
      expect(described_class.new(student_loan_repayment_amount: "don’t know")).not_to be_valid
      expect(described_class.new(student_loan_repayment_amount: "£1,234.56")).not_to be_valid
    end

    it "validates that the loan repayment is under £99,999" do
      expect(described_class.new(student_loan_repayment_amount: 100_000)).not_to be_valid
      expect(described_class.new(student_loan_repayment_amount: 99_999)).to be_valid
    end

    it "validates that the loan repayment is greater than or equal to zero" do
      expect(described_class.new(student_loan_repayment_amount: "-99")).not_to be_valid
      expect(described_class.new(student_loan_repayment_amount: "0")).to be_valid
      expect(described_class.new(student_loan_repayment_amount: "150")).to be_valid
    end

    it "validates that the loan repayment less than £5000 when amending a claim" do
      expect(described_class.new(student_loan_repayment_amount: "5001")).not_to be_valid(:amendment)
      expect(described_class.new(student_loan_repayment_amount: "1200")).to be_valid(:amendment)
    end
  end

  describe "#claim_school_name" do
    it "returns the name of the claim school" do
      eligibility = described_class.new(claim_school: eligible_school)
      expect(eligibility.claim_school_name).to eq eligible_school.name
    end

    it "does not error if the claim school is not set" do
      expect(described_class.new.claim_school_name).to be_nil
    end
  end

  describe "#current_school_name" do
    it "returns the name of the current school" do
      claim = described_class.new(current_school: eligible_school)
      expect(claim.current_school_name).to eq eligible_school.name
    end

    it "does not error if the current school is not set" do
      expect(described_class.new.current_school_name).to be_nil
    end
  end

  describe "#subjects_taught" do
    it "returns an array of the subject attributes that are true" do
      expect(described_class.new.subjects_taught).to eq []
      expect(described_class.new(biology_taught: true, physics_taught: true, chemistry_taught: false).subjects_taught).to eq [:biology_taught, :physics_taught]
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(described_class.new.ineligible?).to eql false
    end

    it "returns true when the qts_award_year is before the qualifying cut-off" do
      expect(described_class.new(qts_award_year: "before_cut_off_date").ineligible?).to eql true
      expect(described_class.new(qts_award_year: "on_or_after_cut_off_date").ineligible?).to eql false
    end

    describe "claim_school eligibility" do
      subject(:eligibility) { described_class.new(claim_school: school) }

      context "when the claim_school is not eligible" do
        let(:school) { ineligible_school }

        it { is_expected.to be_ineligible }
      end

      context "when the claim_school is eligible" do
        let(:school) { eligible_school }

        it { is_expected.not_to be_ineligible }
      end
    end

    describe "current_school eligibility" do
      subject(:eligibility) { described_class.new(current_school: school) }

      context "when the current_school is not eligible" do
        let(:school) { ineligible_school }

        it { is_expected.to be_ineligible }
      end

      context "when the claim_school is eligible" do
        let(:school) { eligible_school }

        it { is_expected.not_to be_ineligible }
      end
    end

    it "returns true when no longer teaching" do
      expect(described_class.new(employment_status: :no_school).ineligible?).to eql true
      expect(described_class.new(employment_status: :claim_school).ineligible?).to eql false
    end

    it "returns true when not teaching an eligible subject" do
      expect(described_class.new(taught_eligible_subjects: false).ineligible?).to eql true
      expect(described_class.new(biology_taught: true).ineligible?).to eql false
    end

    it "returns true when more than half time is spent performing leadership duties" do
      expect(described_class.new(mostly_performed_leadership_duties: true).ineligible?).to eql true
      expect(described_class.new(mostly_performed_leadership_duties: false).ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(described_class.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(described_class.new(qts_award_year: "before_cut_off_date").ineligibility_reason).to eq :ineligible_qts_award_year
      expect(described_class.new(claim_school: ineligible_school).ineligibility_reason).to eq :ineligible_claim_school
      expect(described_class.new(employment_status: :no_school).ineligibility_reason).to eq :employed_at_no_school
      expect(described_class.new(current_school: ineligible_school).ineligibility_reason).to eq :ineligible_current_school
      expect(described_class.new(taught_eligible_subjects: false).ineligibility_reason).to eq :not_taught_eligible_subjects
      expect(described_class.new(mostly_performed_leadership_duties: true).ineligibility_reason).to eq :not_taught_enough
    end
  end

  describe "#award_amount" do
    it "returns the student loan repayment amount" do
      eligibility = described_class.new(student_loan_repayment_amount: 1000)
      expect(eligibility.award_amount).to eq(1000)
    end
  end

  describe "#reset_dependent_answers" do
    let(:eligibility) do
      create(
        :student_loans_eligibility,
        :eligible,
        claim_school: build(:school, :student_loans_eligible),
        current_school: build(:school, :student_loans_eligible),
        taught_eligible_subjects: true,
        chemistry_taught: true,
        physics_taught: true,
        computing_taught: true,
        languages_taught: true,
        employment_status: :different_school,
        had_leadership_position: true
      )
    end

    it "resets employment_status when the value of claim_school changes" do
      eligibility.claim_school = eligibility.claim_school # standard:disable Lint/SelfAssignment
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.claim_school = eligibility.current_school
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.employment_status }
        .from("different_school").to(nil)
    end

    it "resets the current_school_id to nil when the value of claim_school changes" do
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.claim_school = eligibility.current_school
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.current_school_id }
        .from(eligibility.current_school.id).to(nil)
    end

    it "resets the subject fields when the value of the claim_school changes" do
      eligibility.claim_school = eligibility.current_school
      eligibility.reset_dependent_answers

      expect(eligibility.taught_eligible_subjects).to eq(nil)
      expect(eligibility.physics_taught).to eq(nil)
      expect(eligibility.chemistry_taught).to eq(nil)
      expect(eligibility.physics_taught).to eq(nil)
      expect(eligibility.computing_taught).to eq(nil)
      expect(eligibility.languages_taught).to eq(nil)
    end

    it "resets mostly_performed_leadership_duties when the value of had_leadership_position changes" do
      eligibility.had_leadership_position = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.had_leadership_position = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.mostly_performed_leadership_duties }
        .from(false).to(nil)
    end
  end

  # Validation contexts
  context "when saving in the “qts-year” context" do
    it "is not valid without a value for qts_award_year" do
      expect(described_class.new).not_to be_valid(:"qts-year")

      described_class.qts_award_years.each_key do |academic_year|
        expect(described_class.new(qts_award_year: academic_year)).to be_valid(:"qts-year")
      end
    end
  end

  context "when saving in the “claim-school” context" do
    it "validates the presence of the claim_school" do
      expect(described_class.new).not_to be_valid(:"claim-school")
      expect(described_class.new(claim_school: eligible_school)).to be_valid(:"claim-school")
    end
  end

  context "when saving in the “still-teaching” context" do
    it "validates the presence of employment_status" do
      expect(described_class.new).not_to be_valid(:"still-teaching")
      expect(described_class.new(employment_status: :claim_school)).to be_valid(:"still-teaching")
    end

    it "includes the claim school name in the error message" do
      eligibility = build(:student_loans_eligibility, claim_school: eligible_school, employment_status: nil)

      expect(eligibility).not_to be_valid(:"still-teaching")
      expect(eligibility.errors[:employment_status]).to eq(["Select if you still work at #{eligible_school.name}, another school or no longer teach in England"])
    end
  end

  context "when saving in the “current-school” context" do
    it "validates the presence of the current_school" do
      expect(described_class.new).not_to be_valid(:"current-school")
      expect(described_class.new(current_school: eligible_school)).to be_valid(:"current-school")
    end
  end

  context "when saving in the “subjects-taught” context" do
    it "is not valid if none of the subjects-taught attributes are true" do
      expect(described_class.new).not_to be_valid(:"subjects-taught")
      expect(described_class.new(biology_taught: false)).not_to be_valid(:"subjects-taught")
      expect(described_class.new(biology_taught: false, physics_taught: false)).not_to be_valid(:"subjects-taught")
    end

    it "is valid when one or more of the subjects-taught attributes are true" do
      expect(described_class.new(biology_taught: true)).to be_valid(:"subjects-taught")
      expect(described_class.new(biology_taught: true, computing_taught: false)).to be_valid(:"subjects-taught")
      expect(described_class.new(chemistry_taught: true, languages_taught: true)).to be_valid(:"subjects-taught")
    end

    it "is valid with no subjects present if taught_eligible_subjects is false" do
      expect(described_class.new(taught_eligible_subjects: false)).to be_valid(:"subjects-taught")
      expect(described_class.new(taught_eligible_subjects: true)).not_to be_valid(:"subjects-taught")
    end
  end

  context "when saving in the “leadership-position” context" do
    it "is not valid without a value for had_leadership_position" do
      expect(described_class.new).not_to be_valid(:"leadership-position")
      expect(described_class.new(had_leadership_position: true)).to be_valid(:"leadership-position")
      expect(described_class.new(had_leadership_position: false)).to be_valid(:"leadership-position")
    end
  end

  context "when saving in the “mostly-performed-leadership-duties” context" do
    it "is valid when mostly_performed_leadership_duties is present as a boolean value and had_leadership_position is true" do
      expect(described_class.new(had_leadership_position: true)).not_to be_valid(:"mostly-performed-leadership-duties")
      expect(described_class.new(had_leadership_position: true, mostly_performed_leadership_duties: true)).to be_valid(:"mostly-performed-leadership-duties")
      expect(described_class.new(had_leadership_position: true, mostly_performed_leadership_duties: false)).to be_valid(:"mostly-performed-leadership-duties")
    end

    it "is valid when missing if had_leadership_position is false" do
      expect(described_class.new(had_leadership_position: false)).to be_valid(:"mostly-performed-leadership-duties")
    end
  end

  context "when saving in the “submit” context" do
    it "is valid when all attributes are present" do
      expect(build(:student_loans_eligibility, :eligible)).to be_valid(:submit)
    end

    it "is not valid without a value for qts_award_year" do
      expect(build(:student_loans_eligibility, :eligible, qts_award_year: nil)).not_to be_valid(:submit)

      described_class.qts_award_years.each_key do |academic_year|
        expect(build(:student_loans_eligibility, :eligible, qts_award_year: academic_year)).to be_valid(:submit)
      end
    end

    it "is not valid without a value for claim_school" do
      expect(build(:student_loans_eligibility, :eligible, claim_school: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for employment_status" do
      expect(build(:student_loans_eligibility, :eligible, employment_status: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for current_school" do
      expect(build(:student_loans_eligibility, :eligible, current_school: nil)).not_to be_valid(:submit)
    end

    it "is not valid without at least one subject being taught selected" do
      expect(build(:student_loans_eligibility, :eligible, physics_taught: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for had_leadership_position" do
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: nil)).not_to be_valid(:submit)

      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: true)).to be_valid(:submit)
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: false)).to be_valid(:submit)
    end

    it "is not valid without a value for mostly_performed_leadership_duties" do
      expect(build(:student_loans_eligibility, :eligible, mostly_performed_leadership_duties: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for student_loan_repayment_amount" do
      expect(build(:student_loans_eligibility, student_loan_repayment_amount: nil)).not_to be_valid(:submit)
    end
  end

  describe "#eligible_itt_subject" do
    it "returns nil" do
      expect(described_class.new.eligible_itt_subject).to be(nil)
    end
  end

  describe "#ineligible_qts_award_year?" do
    subject { described_class.new(qts_award_year:).ineligible_qts_award_year? }

    context "when the qts award year is eligibile" do
      let(:qts_award_year) { "on_or_after_cut_off_date" }

      it { is_expected.to eq(false) }
    end

    context "when the qts award year is not eligible" do
      let(:qts_award_year) { "before_cut_off_date" }

      it { is_expected.to eq(true) }
    end
  end

  describe "#set_qualifications_from_dqt_record" do
    let(:eligibility) { build(:student_loans_eligibility, claim:, qts_award_year:) }
    let(:claim) { build(:claim, policy: Policies::StudentLoans, qualifications_details_check:) }
    let(:qts_award_year) { nil }

    context "when user has confirmed their qualification details" do
      let(:qualifications_details_check) { true }
      let(:qts_award_date) { Date.new(1981, 1, 1) }

      before { allow(claim).to receive(:dqt_teacher_record).and_return(double(eligible_qts_award_date?: eligible, qts_award_date:)) }

      context "when the DQT payload QTS award date is eligible" do
        let(:eligible) { true }

        it "sets the qts_award_year to on_or_after_cut_off_date" do
          expect { eligibility.set_qualifications_from_dqt_record }.to change { eligibility.qts_award_year }.from(qts_award_year).to("on_or_after_cut_off_date")
        end
      end

      context "when the DQT payload QTS award date is not eligible" do
        let(:eligible) { false }

        it "sets the qts_award_year to before_cut_off_date" do
          expect { eligibility.set_qualifications_from_dqt_record }.to change { eligibility.qts_award_year }.from(qts_award_year).to("before_cut_off_date")
        end
      end

      context "when the DQT payload QTS award date is nil" do
        let(:eligible) { nil }
        let(:qts_award_date) { nil }

        it "does not change the qts_award_year" do
          expect { eligibility.set_qualifications_from_dqt_record }.not_to change { eligibility.qts_award_year }
        end
      end
    end

    context "when user has not confirmed their qualification details" do
      let(:qualifications_details_check) { false }
      let(:qts_award_year) { :on_or_after_cut_off_date }

      it "sets the qts_award_year to nil" do
        expect { eligibility.set_qualifications_from_dqt_record }.to change { eligibility.qts_award_year }.from(qts_award_year.to_s).to(nil)
      end
    end
  end
end
