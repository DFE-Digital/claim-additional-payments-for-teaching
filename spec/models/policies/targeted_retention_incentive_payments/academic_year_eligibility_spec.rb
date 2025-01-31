require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::AcademicYearEligibility do
  describe ".new" do
    specify { expect { described_class.new(nil) }.to raise_error("nil academic year") }
  end

  describe "#eligible?" do
    context "inside range" do
      specify {
        expect(
          [
            described_class.new(AcademicYear.new("2017/2018")),
            described_class.new(AcademicYear.new("2018/2019")),
            described_class.new(AcademicYear.new("2019/2020")),
            described_class.new(AcademicYear.new("2020/2021")),
            described_class.new(AcademicYear.new("2021/2022")),
            described_class.new(AcademicYear.new("2022/2023")),
            described_class.new(AcademicYear.new("2023/2024"))
          ]
        ).to all(be_eligible)
      }
    end

    context "outside range" do
      specify { expect(described_class.new(AcademicYear.new("2016/2017"))).to_not be_eligible }
      specify { expect(described_class.new(AcademicYear.new("2024/2025"))).to_not be_eligible }
    end
  end
end
