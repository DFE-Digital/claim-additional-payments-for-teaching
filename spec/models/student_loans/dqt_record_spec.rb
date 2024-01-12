require "rails_helper"

RSpec.describe StudentLoans::DqtRecord do
  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }

  describe "#eligble?" do
    subject(:result) { StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date:})).eligible? }

    context "QTS award date is after the first eligible academic year" do
      let(:qts_award_date) { Date.new(2017, 3, 19) }
      it { is_expected.to eq true }
    end

    context "QTS award date is in the first eligible academic year" do
      let(:qts_award_date) { Date.new(2014, 10, 1) }
      it { is_expected.to eq true }
    end

    context "QTS award date is not an eligible year" do
      let(:qts_award_date) { Date.new(2000, 3, 8) }
      it { is_expected.to eq false }
    end

    context "QTS award date is blank" do
      let(:qts_award_date) { "" }
      it { is_expected.to eq false }
    end

    context "when the date is after academic year 2020/21" do
      let(:qts_award_date) { Date.new(2021, 9, 30) }
      it { is_expected.to eq false }
    end
  end

  describe "#eligible_qts_award_date?" do
    subject(:result) { StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date:})).eligible_qts_award_date? }

    context "QTS award date is after the first eligible academic year" do
      let(:qts_award_date) { Date.new(2017, 3, 19) }
      it { is_expected.to eq true }
    end

    context "QTS award date is in the first eligible academic year" do
      let(:qts_award_date) { Date.new(2014, 10, 1) }
      it { is_expected.to eq true }
    end

    context "QTS award date is not an eligible year" do
      let(:qts_award_date) { Date.new(2000, 3, 8) }
      it { is_expected.to eq false }
    end

    context "QTS award date is not an eligible year" do
      let(:qts_award_date) { Date.new(2013, 8, 15) }
      it { is_expected.to eq false }
    end

    context "in academic year 2029/30" do
      let(:qts_award_date) { Date.new(2018, 7, 1) }
      let!(:policy_configuration) { create(:policy_configuration, :student_loans, current_academic_year: "2029/2030") }

      it { is_expected.to eq false }
    end

    context "QTS award date is blank" do
      let(:qts_award_date) { "" }
      it { is_expected.to eq false }
    end

    context "when the date is after academic year 2020/21" do
      let(:qts_award_date) { Date.new(2021, 9, 30) }
      it { is_expected.to eq false }
    end
  end
end
