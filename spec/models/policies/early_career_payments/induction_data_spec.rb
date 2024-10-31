require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::InductionData do
  subject { described_class.new(itt_year:, induction_status:, induction_start_date:) }
  let(:induction_start_date) { nil }

  shared_examples :eligible? do |statuses, expected|
    subject { super().eligible? }

    statuses.each do |status|
      context "when the status is '#{status}'" do
        let(:induction_status) { status }

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe "#eligible?" do
    context "when the ITT year is 2018" do
      let(:itt_year) { AcademicYear.new(2018) }

      include_examples :eligible?, ["pass", "exempt"], true
      include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], false
      include_examples :eligible?, ["required to complete", "failed"], false
    end

    context "when the ITT year is 2019" do
      let(:itt_year) { AcademicYear.new(2019) }

      include_examples :eligible?, ["pass", "exempt"], true
      include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], false
      include_examples :eligible?, ["required to complete", "failed"], false
    end

    context "when the ITT year is 2020" do
      let(:itt_year) { AcademicYear.new(2020) }

      context "when the start date is more than 1 year old" do
        let(:induction_start_date) { 1.year.ago }

        include_examples :eligible?, ["pass", "exempt"], true
        include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], true
        include_examples :eligible?, ["required to complete", "failed"], false
      end

      context "when the start date is less than 1 year old" do
        let(:induction_start_date) { 1.year.ago + 1.day }

        include_examples :eligible?, ["exempt"], true
        include_examples :eligible?, ["pass"], false
        include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], false
        include_examples :eligible?, ["required to complete", "failed"], false
      end

      context "when the start date is missing" do
        let(:induction_start_date) { nil }

        include_examples :eligible?, ["exempt"], true
        include_examples :eligible?, ["pass"], false
        include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], false
        include_examples :eligible?, ["required to complete", "failed"], false
      end
    end

    context "when the ITT year is after 2020" do
      let(:itt_year) { AcademicYear.new(2021) }

      include_examples :eligible?, ["pass", "exempt"], false
      include_examples :eligible?, ["in progress", "not yet completed", "induction extended"], false
      include_examples :eligible?, ["required to complete", "failed"], false
    end
  end

  describe "#incomplete?" do
    subject { super().incomplete? }

    context "when the status is missing" do
      let(:induction_status) { nil }

      context "with ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        it { is_expected.to eq(true) }
      end

      context "with ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        it { is_expected.to eq(true) }
      end

      context "with ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        it { is_expected.to eq(true) }
      end
    end

    context "when the status is present but the start date is missing" do
      let(:induction_status) { "Pass" }
      let(:induction_start_date) { nil }

      context "with ITT year 2018" do
        let(:itt_year) { AcademicYear.new(2018) }

        it { is_expected.to eq(false) }
      end

      context "with ITT year 2019" do
        let(:itt_year) { AcademicYear.new(2019) }

        it { is_expected.to eq(false) }
      end

      context "with ITT year 2020" do
        let(:itt_year) { AcademicYear.new(2020) }

        context "when the status is valid" do
          let(:induction_status) { "Pass" }

          it { is_expected.to eq(true) }
        end

        context "when the status is valid but it's 'exempt'" do
          let(:induction_status) { "Exempt" }

          it { is_expected.to eq(false) }
        end

        context "when the status is not valid" do
          let(:induction_status) { "Failed" }

          it { is_expected.to eq(false) }
        end
      end
    end
  end
end
