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

    specify { expect { described_class.new(school: eligible_school_for_2022_23, year: academic_year_2021_22) }.to raise_error("no LUP award mapping for 2021/2022") }
    specify { expect { described_class.new(school: eligible_school_for_2022_23, year: academic_year_2022_23) }.not_to raise_error }
    specify { expect { described_class.new(school: eligible_school_for_2022_23, year: academic_year_2023_24) }.to raise_error("no LUP award mapping for 2023/2024") }
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
      specify { expect(subject.values.sum).to eq(5_917_500) }
      specify { expect(subject.values.uniq).to contain_exactly(1_500, 2_000, 2_500, 3_000) }
      specify { expect(subject.count).to eq(2_745) }
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
          149205 => 2_500 # last eligible school
        )
      }
      specify { expect(subject).to be_frozen }
    end
  end
end
