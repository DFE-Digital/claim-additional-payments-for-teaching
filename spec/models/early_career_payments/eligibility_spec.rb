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

  describe "#eligible_later_year" do
    let!(:claim) { build_stubbed(:claim, academic_year: claim_academic_year, eligibility: eligibility) }
    let(:claim_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }
    let(:eligibility) do
      build(
        :early_career_payments_eligibility,
        eligible_itt_subject: itt_subject,
        itt_academic_year: itt_academic_year
      )
    end

    context "when academic year is 2022/23" do
      before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

      context "when claim is eligible later" do
        [
          {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019)), claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2024))},
          {itt_subject: "mathematics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)), claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023))},
          {itt_subject: "physics", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)), claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023))},
          {itt_subject: "chemistry", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)), claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023))},
          {itt_subject: "foreign_languages", itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)), claim_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023))}
        ].each do |context|
          context "with ITT subject #{context[:itt_subject].to_s.humanize}" do
            let(:itt_subject) { context[:itt_subject] }

            context "with ITT academic year #{context[:itt_academic_year]}" do
              let(:itt_academic_year) { context[:itt_academic_year] }

              it "returns the next eligible claim academic year" do
                expect(eligibility.eligible_later_year).to be_an_instance_of(AcademicYear)
                expect(eligibility.eligible_later_year).to eql AcademicYear.new(context[:claim_academic_year])
              end
            end
          end
        end
      end

      context "when claim is not eligible later" do
        let(:itt_subject) { "chemistry" }
        let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

        it "does not return the next eligbilbe claim academic year " do
          expect(eligibility.eligible_later_year).to be_an_instance_of(NilClass)
          expect(eligibility.eligible_later_year).to be_nil
        end
      end
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

  describe "#first_eligible_itt_academic_year" do
    it { should respond_to(:first_eligible_itt_academic_year) }
  end

  describe "#reset_dependent_answers" do
    let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
    let!(:claim) { build_stubbed(:claim, :with_student_loan, eligibility: eligibility) }

    let(:eligibility) do
      build_stubbed(
        :early_career_payments_eligibility,
        :eligible,
        employed_as_supply_teacher: true,
        has_entire_term_contract: false,
        employed_directly: false,
        qualification: :undergraduate_itt,
        eligible_itt_subject: :none_of_the_above,
        teaching_subject_now: false
      )
    end

    it "resets 'eligible_itt_subject' when value of 'qualification' changes" do
      eligibility.qualification = :undergraduate_itt
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.qualification = :postgraduate_itt
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.eligible_itt_subject }
        .from("none_of_the_above").to(nil)
    end

    it "resets 'teaching_subject_now' when value of 'qualification' changes" do
      eligibility.qualification = :undergraduate_itt
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.qualification = :postgraduate_itt
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.teaching_subject_now }
        .from(false).to(nil)
    end

    it "resets 'teaching_subject_now' when value of 'eligible_itt_subject' changes" do
      eligibility.eligible_itt_subject = :none_of_the_above
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.eligible_itt_subject = :foreign_languages
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.teaching_subject_now }
        .from(false).to(nil)
    end

    it "resets 'has_entire_term_contract' when the value of 'employed_as_supply_teacher' changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_entire_term_contract }
        .from(false).to(nil)
    end

    it "resets 'employed_directly' when the value of 'employed_as_supply_teacher' changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.employed_directly }
        .from(false).to(nil)
    end
  end

  describe "#trainee_teacher?" do
    let(:eligibility) { build_stubbed(:early_career_payments_eligibility, nqt_in_academic_year_after_itt: false) }

    before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

    it "returns true" do
      expect(eligibility).to be_a_trainee_teacher
    end

    it "returns false" do
      eligibility.nqt_in_academic_year_after_itt = true
      expect(eligibility).to_not be_a_trainee_teacher
    end
  end

  describe "#induction_not_completed?" do
    subject { eligibility.induction_not_completed? }
    let(:eligibility) { build_stubbed(:early_career_payments_eligibility, induction_completed:) }

    context "when the induction_completed attribute is nil" do
      let(:induction_completed) { nil }

      it { is_expected.to eq(false) }
    end

    context "when the induction_completed attribute is false" do
      let(:induction_completed) { false }

      it { is_expected.to eq(true) }
    end

    context "when the induction_completed attribute is true" do
      let(:induction_completed) { true }

      it { is_expected.to eq(false) }
    end
  end

  describe "#ecp_only_school?" do
    subject { eligibility.ecp_only_school? }
    let!(:policy_config) { create(:journey_configuration, :additional_payments) }
    let!(:claim) { build_stubbed(:claim, eligibility: eligibility) }

    context "when the current school is eligible for ECP and LUP" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_school_ecp_and_lup) }

      it { is_expected.to eq(false) }
    end

    context "when the current school is eligible for ECP only" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_school_ecp_only) }

      it { is_expected.to eq(true) }
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
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: 7_501)).not_to be_valid(:amendment)
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: 7_500)).to be_valid(:amendment)
        expect(Policies::EarlyCareerPayments::Eligibility.new(award_amount: 7_499)).to be_valid(:amendment)
      end
    end
  end

  describe ".max_award_amount_in_pounds" do
    specify { expect(described_class.max_award_amount_in_pounds).to eq(7_500) }
  end

  it_behaves_like "Eligibility status", :early_career_payments

  context "ECP-specific eligibility" do
    subject { eligibility.status }

    before { create(:journey_configuration, :additional_payments) }

    # By the 2022 policy year it's too late for this to apply to LUP so is ECP-specific now but
    # technically this check is generally needed for all policies
    context "no eligible subjects" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :no_eligible_subjects) }

      it { is_expected.to eq(:ineligible) }
    end

    context "ineligible ITT subject" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :ineligible_itt_subject) }

      it { is_expected.to eq(:ineligible) }
    end

    context "'None of the above' ITT subject" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:ineligible) }
    end

    context "trainee teacher" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :trainee_teacher) }

      it { is_expected.to eq(:ineligible) }
    end

    context "induction completed" do
      let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :induction_completed) }

      it { is_expected.to eq(:eligible_now) }
    end

    context "induction not completed" do
      let!(:claim) { build_stubbed(:claim, eligibility: eligibility) }

      context "with an ECP-only eligible school" do
        let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :induction_not_completed, :eligible_school_ecp_only) }

        it { is_expected.to eq(:eligible_later) }
      end

      context "with an ECP and LUP eligible school" do
        let(:eligibility) { create(:early_career_payments_eligibility, :eligible_now, :induction_not_completed, :eligible_school_ecp_and_lup) }

        it { is_expected.to eq(:ineligible) }
      end
    end
  end
end
