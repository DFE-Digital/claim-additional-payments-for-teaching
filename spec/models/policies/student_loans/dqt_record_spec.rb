require "rails_helper"

RSpec.describe Policies::StudentLoans::DqtRecord do
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  let(:dqt_record) do
    described_class.new(OpenStruct.new({qts_award_date:}))
  end

  describe "#eligble?" do
    subject(:result) { dqt_record.eligible? }

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
    subject(:result) { dqt_record.eligible_qts_award_date? }

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
      let!(:journey_configuration) { create(:journey_configuration, :student_loans, current_academic_year: "2029/2030") }

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

  describe "#has_no_data_for_claim?" do
    subject(:dqt_record) { described_class.new(record: nil) }

    context "when one or more required data are present" do
      before { allow(dqt_record).to receive(:qts_award_date).and_return("test") }

      it { is_expected.not_to be_has_no_data_for_claim }
    end

    context "when all required data are not present" do
      before { allow(dqt_record).to receive(:qts_award_date).and_return(nil) }

      it { is_expected.to be_has_no_data_for_claim }
    end
  end
end
