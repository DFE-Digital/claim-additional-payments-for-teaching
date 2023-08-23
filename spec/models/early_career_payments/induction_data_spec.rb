require "rails_helper"

RSpec.describe EarlyCareerPayments::InductionData do
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

        include_examples :eligible?, ["pass", "exempt"], false
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
end
