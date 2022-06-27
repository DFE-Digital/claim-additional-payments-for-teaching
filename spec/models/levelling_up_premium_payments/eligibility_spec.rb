require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Eligibility, type: :model do
  subject { build(:levelling_up_premium_payments_eligibility) }

  describe "associations" do
    it { should have_one(:claim) }
    it { should belong_to(:current_school).class_name("School").optional(true) }
  end

  describe "#policy" do
    specify { expect(subject.policy).to eq(LevellingUpPremiumPayments) }
  end

  describe "#ineligible?" do
    specify { expect(subject).to respond_to(:ineligible?) }

    context "when ITT year is 2017" do
      before do
        subject.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new(2017))
      end

      it "returns false" do
        expect(subject.ineligible?).to eql false
      end
    end

    describe "ITT subject" do
      let(:eligible) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      context "without eligible degree" do
        before { eligible.eligible_degree_subject = false }

        it "is eligible then switches to ineligible with a non-LUP ITT subject" do
          expect(eligible).not_to be_ineligible
          eligible.itt_subject_foreign_languages!
          expect(eligible).to be_ineligible
        end
      end
    end
  end

  describe "#eligible_now?" do
    context "eligible" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible) }

      it { is_expected.to be_eligible_now }
    end

    context "ineligible" do
      subject { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.not_to be_eligible_now }
    end
  end

  describe "#eligible_later?" do
    context "eligible" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible) }

      it { is_expected.to be_eligible_later }
    end

    context "ineligible" do
      subject { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.not_to be_eligible_later }
    end
  end

  describe "#award_amount" do
    it { should_not allow_values(0, nil).for(:award_amount).on(:amendment) }
    it { should validate_numericality_of(:award_amount).on(:amendment).is_greater_than(0).is_less_than_or_equal_to(3_000).with_message("Enter a positive amount up to £3,000.00 (inclusive)") }
  end
end
