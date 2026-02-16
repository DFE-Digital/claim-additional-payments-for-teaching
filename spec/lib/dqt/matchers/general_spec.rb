require "rails_helper"

RSpec.describe Dqt::Matchers::General do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  subject(:described_class) do
    Class.new do
      include Dqt::Matchers::General

      attr_reader :record, :claim

      def initialize(record, claim)
        @record = record
        @claim = claim
      end

      delegate(*%i[
        degree_codes
        itt_subjects
        itt_subject_codes
        itt_start_date
        qts_award_date
        qualification_name
      ], to: :record)

      delegate(
        :qualification,
        :itt_academic_year,
        :academic_year,
        :eligible_itt_subject,
        to: :claim
      )
    end.new(record, claim)
  end

  let(:degree_codes) { nil }
  let(:itt_subjects) { nil }
  let(:itt_subject_codes) { nil }
  let(:itt_start_date) { nil }
  let(:qts_award_date) { nil }
  let(:qualification_name) { nil }

  let(:record) do
    OpenStruct.new(
      {
        degree_codes:,
        itt_subjects:,
        itt_subject_codes:,
        itt_start_date:,
        qts_award_date:,
        qualification_name:
      }
    )
  end

  let(:claim) do
    OpenStruct.new(
      {
        qualification: qualification,
        itt_academic_year: itt_academic_year,
        academic_year: claim_academic_year,
        eligible_itt_subject: eligible_itt_subject
      }
    )
  end

  let(:claim_academic_year) do
    Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year
  end

  let(:itt_academic_year) { claim_academic_year - 1 }

  let(:qualification) { "postgraduate_itt" }

  let(:eligible_itt_subject) { "mathematics" }

  describe ".academic_date" do
    subject { described_class.academic_date }

    let(:itt_start_date) { Date.parse("1/9/2019") }
    let(:qts_award_date) { Date.parse("30/9/2019") }

    context "when the route is Undergraduate ITT" do
      let(:qualification_name) { "Primary and secondary undergraduate fee funded" }

      it "returns the QTS Award date" do
        is_expected.to eq(qts_award_date)
      end
    end

    context "when the route is Assessment Only" do
      let(:qualification_name) { "Assessment Only" }

      it "returns the QTS Award date" do
        is_expected.to eq(qts_award_date)
      end
    end

    context "when the route is Overseas Recognition" do
      let(:qualification_name) { "Apply for Qualified Teacher Status in England" }

      it "returns the QTS Award date" do
        is_expected.to eq(qts_award_date)
      end
    end

    shared_context :itt_start_date_nil do
      context "when the ITT start date is nil" do
        let(:itt_start_date) { nil }

        it "returns nil" do
          is_expected.to be_nil
        end
      end
    end

    context "when the route is Postgraduate ITT" do
      let(:qualification_name) { "Core" }

      context "when the ITT Start date is before the 18th of August" do
        let(:itt_start_date) { Date.parse("17/8/2019") }

        it "returns the ITT Start date" do
          is_expected.to eq(itt_start_date)
        end

        include_context :itt_start_date_nil
      end

      context "when the ITT Start date is between the 18th and 31st of August" do
        let(:itt_start_date) { Date.parse("18/8/2019") }

        it "returns the ITT Start date shifted to the 1st of September" do
          is_expected.to eq(itt_start_date.next_month.beginning_of_month)
        end

        include_context :itt_start_date_nil
      end

      context "when the ITT Start date is on or after the 1st of September" do
        let(:itt_start_date) { Date.parse("2/9/2019") }

        it "returns the ITT Start date" do
          is_expected.to eq(itt_start_date)
        end

        include_context :itt_start_date_nil
      end
    end

    context "when the route is undetermined" do
      let(:qualification_name) { "Invalid name" }

      it "returns nil" do
        is_expected.to be_nil
      end
    end
  end

  describe ".itt_year" do
    subject(:itt_year) { described_class.itt_year }

    let(:qualification_name) { "Primary and secondary undergraduate fee funded" }
    let(:itt_start_date) { Date.parse("1/9/2019") }

    before do
      allow(AcademicYear).to receive(:for)
      itt_year
    end

    it "returns the Academic year based on the calculated academic date" do
      expect(AcademicYear).to have_received(:for).with(described_class.academic_date)
    end
  end

  describe ".eligible_qualification?" do
    subject { described_class.eligible_qualification? }

    context "when the qualification name belongs to the qualification category on the claim" do
      let(:qualification_name) { "Primary and secondary undergraduate fee funded" }
      let(:qualification) { :undergraduate_itt }

      it { is_expected.to eq(true) }
    end

    context "when the qualification name does not belong to the qualification category on the claim" do
      let(:qualification_name) { "Assessment Only" }
      let(:qualification) { :undergraduate_itt }

      it { is_expected.to eq(false) }
    end
  end

  describe ".qts_award_date_after_itt_start_date?" do
    subject { described_class.qts_award_date_after_itt_start_date? }

    context "when the route is Undergraduate ITT" do
      let(:qualification_name) { "Primary and secondary undergraduate fee funded" }

      it { is_expected.to eq(true) }
    end

    context "when the route is Assessment Only" do
      let(:qualification_name) { "Assessment Only" }

      it { is_expected.to eq(true) }
    end

    context "when the route is Overseas Recognition" do
      let(:qualification_name) { "Apply for Qualified Teacher Status in England" }

      it { is_expected.to eq(true) }
    end

    context "when the route is Postgraduate ITT" do
      let(:qualification_name) { "Core" }

      context "when the QTS Award date is blank" do
        let(:qts_award_date) { nil }

        it { is_expected.to eq(false) }
      end

      context "when the QTS Award date is before the ITT Start date" do
        let(:itt_start_date) { Date.parse("1/9/2019") }
        let(:qts_award_date) { itt_start_date - 1.day }

        it { is_expected.to eq(false) }
      end

      context "when the QTS Award date is after the ITT Start date" do
        let(:itt_start_date) { Date.parse("1/9/2019") }
        let(:qts_award_date) { itt_start_date + 1.day }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe ".route_into_teaching" do
    subject { described_class.route_into_teaching }

    described_class::QUALIFICATION_MATCHING_TYPE.each do |category, qualifications|
      qualifications.each do |qualification|
        context "when the qualification is #{qualification}" do
          let(:qualification_name) { qualification }

          it { is_expected.to eq(category) }
        end
      end
    end

    context "when case is different" do
      let(:qualification_name) { "ASSESSMENT ONLY" }

      it "ignores case and returns a match" do
        expect(subject).to eq :assessment_only
      end
    end
  end
end
