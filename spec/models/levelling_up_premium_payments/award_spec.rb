require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Award do
  let(:eligible_school_for_2022_23) { build(:school, :levelling_up_premium_payments_eligible) }
  let(:ineligible_school_for_2022_23) { build(:school, :levelling_up_premium_payments_ineligible) }

  let(:academic_year_2021_22) { AcademicYear.new(2021) }
  let(:academic_year_2022_23) { AcademicYear.new(2022) }
  let(:academic_year_2023_24) { AcademicYear.new(2023) }

  describe ".new" do
    specify { expect { described_class.new(school: nil, year: academic_year_2022_23) }.to raise_error("nil school") }
    specify { expect { described_class.new(school: eligible_school_for_2022_23, year: nil) }.to raise_error("nil year") }
  end

  context "eligible" do
    let(:eligible) { described_class.new(school: eligible_school_for_2022_23, year: academic_year_2022_23) }

    specify { expect(eligible).to have_award }
    specify { expect(eligible.amount_in_pounds).to be_positive }
  end

  context "ineligible" do
    let(:ineligible) { described_class.new(school: ineligible_school_for_2022_23, year: academic_year_2022_23) }

    specify { expect(ineligible).to_not have_award }
    specify { expect(ineligible.amount_in_pounds).to be_zero }
  end

  describe ".max" do
    specify { expect(described_class.max(academic_year_2022_23)).to eq(3_000) }
  end

  describe ".urn_to_award_amount_in_pounds" do
    context "2022/23" do
      subject { described_class.urn_to_award_amount_in_pounds(academic_year_2022_23) }

      # *attempt* to check if the hash has been altered
      specify { expect(subject.values).to all be_positive }
      specify { expect(subject.values.sum).to eq(5_764_500) }
      specify { expect(subject.values.uniq).to contain_exactly(1_500, 2_000, 2_500, 3_000) }
      specify { expect(subject.count).to eq(2_655) }
      specify {
        expect(subject).not_to include(
          100182, # first ineligible school
          148866 # last ineligible school
        )
      }
      specify {
        expect(subject).to include(
          100006 => 2_000, # first eligible school (£2,000 award)
          100053 => 1_500, # first £1,500 award
          103760 => 2_500, # first £2,500 award
          103765 => 3_000, # first £3,000 award
          148965 => 3_000 # last eligible school
        )
      }
      specify { expect(subject).to be_frozen }
    end

    context "2023/24" do
      subject { described_class.urn_to_award_amount_in_pounds(academic_year_2023_24) }

      # In 2022/23 we don't know for now what the values are. Future developers will
      # need to fill this in
      specify { expect(subject).to be_empty }
    end
  end
end
