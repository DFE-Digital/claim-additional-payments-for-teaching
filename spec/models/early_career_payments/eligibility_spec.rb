# frozen_string_literal: true

require "rails_helper"

RSpec.describe EarlyCareerPayments::Eligibility, type: :model do
  describe "#policy" do
    let(:early_career_payments_eligibility) { build(:early_career_payments_eligibility) }

    it "has a policy class of 'EarlyCareerPayments'" do
      expect(early_career_payments_eligibility.policy).to eq EarlyCareerPayments
    end
  end

  describe "qualification attribute" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(qualification: "non-existance") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(qualification: "postgraduate_itt")

      expect(eligibility.postgraduate_itt?).to eq true
      expect(eligibility.undergraduate_itt?).to eq false
      expect(eligibility.assessment_only?).to eq false
      expect(eligibility.overseas_recognition?).to eq false
    end
  end

  describe "eligible_itt_subject attribute" do
    it "rejects invalid values" do
      expect { EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "not-in-list-of-options") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = EarlyCareerPayments::Eligibility.new(eligible_itt_subject: "foreign_languages")

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

  describe "#ineligibility_reason" do
    let(:eligibility) do
      build(
        :early_career_payments_eligibility,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
        eligible_itt_subject: :mathematics
      )
    end

    [
      {policy_year: AcademicYear::Type.new.serialize(AcademicYear.new(2022)), ineligibility_reason: :generic_ineligibility}
    ].each do |scenario|
      context "with a policy configuration for #{scenario[:policy_year]}" do
        before do
          @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: scenario[:policy_year])

          build_stubbed(
            :claim,
            academic_year: scenario[:policy_year],
            eligibility: eligibility
          )
        end

        after do
          PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
        end

        it "returns a symbol indicating the reason for ineligibility" do
          eligibility.nqt_in_academic_year_after_itt = true
          expect(eligibility.ineligibility_reason).to be_nil

          # TODO: CAPT-350 means this is ineligible, CAPT-392 will add an additional question if :none_of_the_above
          eligibility.nqt_in_academic_year_after_itt = false
          eligibility.eligible_itt_subject = :none_of_the_above
          expect(eligibility.ineligibility_reason).to eql scenario[:ineligibility_reason]

          expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true).ineligibility_reason).to eq :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true).ineligibility_reason).to eql :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(subject_to_formal_performance_action: true, subject_to_disciplinary_action: true).ineligibility_reason).to eq :generic_ineligibility
          expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above).ineligibility_reason).to eq :itt_subject_none_of_the_above
          expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false).ineligibility_reason).to eql :not_teaching_now_in_eligible_itt_subject
          expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: AcademicYear.new).ineligibility_reason).to eq :generic_ineligibility
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

    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    it "returns true" do
      expect(eligibility).to be_a_trainee_teacher
    end

    it "returns false" do
      eligibility.nqt_in_academic_year_after_itt = true
      expect(eligibility).to_not be_a_trainee_teacher
    end
  end

  describe "validation contexts" do
    context "award_amount attribute" do
      it "validates the award_amount is numerical" do
        expect(EarlyCareerPayments::Eligibility.new(award_amount: "don't know")).not_to be_valid
        expect(EarlyCareerPayments::Eligibility.new(award_amount: "£2,000.00")).not_to be_valid
      end

      it "validates that award_amount is a positive number" do
        expect(EarlyCareerPayments::Eligibility.new(award_amount: -1_000)).not_to be_valid
        expect(EarlyCareerPayments::Eligibility.new(award_amount: 2_500)).to be_valid
      end

      it "validates that award_amount can be zero" do
        expect(EarlyCareerPayments::Eligibility.new(award_amount: 0)).to be_valid
      end

      it "validates that the award_amount is less than £7,500 when amending a claim" do
        expect(EarlyCareerPayments::Eligibility.new(award_amount: 7_501)).not_to be_valid(:amendment)
        expect(EarlyCareerPayments::Eligibility.new(award_amount: 7_500)).to be_valid(:amendment)
        expect(EarlyCareerPayments::Eligibility.new(award_amount: 7_499)).to be_valid(:amendment)
      end
    end

    context "when saving in the 'nqt_in_academic_year_after_itt' context" do
      it "is not valid without a value for 'nqt_in_academic_year_after_itt'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"nqt-in-academic-year-after-itt")
        expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: true)).to be_valid(:"nqt-in-academic-year-after-itt")
        expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false)).to be_valid(:"nqt-in-academic-year-after-itt")
      end
    end

    context "when saving in the 'employed_as_supply_teacher' context" do
      it "is not valid without a value for 'employed_as_supply_teacher'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"supply-teacher")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).to be_valid(:"supply-teacher")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: false)).to be_valid(:"supply-teacher")
      end
    end

    context "when saving in the 'has_entire_term_contract' context" do
      it "is not valid without a value for 'has_entire_term_contract'" do
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"entire-term-contract")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false)).to be_valid(:"entire-term-contract")
      end
    end

    context "when saving in the 'employed_directly' context" do
      it "is not valid without a value for 'employed_directly'" do
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"employed-directly")
        expect(EarlyCareerPayments::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false)).to be_valid(:"employed-directly")
      end
    end

    context "when saving in the 'poor-peformance' context" do
      it "is not valid without a value for 'subject_to_disciplinary_action" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"poor-performance")
      end

      it "is not valid without a value for 'subject_to_formal_performance_action'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"poor-performance")
      end

      it "is valid when the values are not nil" do
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: false)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: false, subject_to_formal_performance_action: false)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: true)).to be_valid(:"poor-performance")
        expect(EarlyCareerPayments::Eligibility.new(subject_to_disciplinary_action: true, subject_to_formal_performance_action: true)).to be_valid(:"poor-performance")
      end
    end

    context "when saving in the 'qualification' context" do
      it "is not valid without a value for 'qualification'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:qualification)
      end
    end

    context "when saving in the 'eligible_itt_subject' context" do
      it "is not valid without a value for 'eligible_itt_subject'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"eligible-itt-subject")
      end

      it "is not valid when the value for 'eligible_itt_subject' is 'none of the above'" do
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :none_of_the_above)).to be_valid(:"eligible-itt-subject")
      end

      it "is valid when the value for 'eligible_itt_subject' is one of 'chemistry, foreign_languages, mathematics or physics'" do
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :chemistry)).to be_valid(:"eligible-itt-subject")
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :physics)).to be_valid(:"eligible-itt-subject")
        expect(EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :foreign_languages)).to be_valid(:"eligible-itt-subject")
        expect { EarlyCareerPayments::Eligibility.new(eligible_itt_subject: :languages) }.to raise_error(ArgumentError)
      end
    end

    context "when saving in the 'teaching_subject_now' context" do
      it "is not valid without a value for 'teaching_subject_now'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"teaching-subject-now")
        expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: true)).to be_valid(:"teaching-subject-now")
        expect(EarlyCareerPayments::Eligibility.new(teaching_subject_now: false)).to be_valid(:"teaching-subject-now")
      end
    end

    context "when saving in the 'itt_academic_year' context" do
      it "is not valid without a value for 'itt_academic_year'" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"itt-year")
        expect(EarlyCareerPayments::Eligibility.new(itt_academic_year: AcademicYear.new(2020))).to be_valid(:"itt-year")
      end
    end
  end

  describe ".max_award_amount_in_pounds" do
    specify { expect(described_class.max_award_amount_in_pounds).to eq(7_500) }
  end

  it_behaves_like "Eligibility status", :early_career_payments_eligibility

  context "ECP-specific eligibility" do
    subject { eligibility.status }

    # By the 2022 policy year it's too late for this to apply to LUP so is ECP-specific now but
    # technically this check is generally needed for all policies
    context "no eligible subjects" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_now, :no_eligible_subjects) }

      it { is_expected.to eq(:ineligible) }
    end

    context "ineligible ITT subject" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_now, :ineligible_itt_subject) }

      it { is_expected.to eq(:ineligible) }
    end

    context "'None of the above' ITT subject" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_now, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:ineligible) }
    end

    context "trainee teacher" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_now, :trainee_teacher) }

      it { is_expected.to eq(:ineligible) }
    end
  end

  describe "#eligible_now_and_again_sometime?" do
    subject { eligibility }

    context "ineligible now but eligible next year" do
      let(:eligibility) { build(:early_career_payments_eligibility, :ineligible_now_but_eligible_next_year) }

      specify { expect(subject.status).to eq(:eligible_later) }

      it "is not eligible *again* in the future because it's not even eligible now" do
        is_expected.not_to be_eligible_now_and_again_sometime
      end
    end

    context "eligible now and again next year" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_next_year_too) }

      specify { expect(subject.status).to eq(:eligible_now) }

      it { is_expected.to be_eligible_now_and_again_sometime }
    end

    context "eligible now and again but two years later (so not next year)" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible_now_and_again_but_two_years_later) }

      specify { expect(subject.status).to eq(:eligible_now) }

      it { is_expected.to be_eligible_now_and_again_sometime }
    end
  end
end
