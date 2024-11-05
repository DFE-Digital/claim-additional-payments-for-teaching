# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::Eligibility do
  let(:eligibility) { build(:early_years_payments_eligibility, :eligible) }

  describe "#employment_task_available_at" do
    subject { eligibility.employment_task_available_at }

    it { is_expected.to eq eligibility.start_date + 6.months }
  end

  describe "#employment_task_available?" do
    subject { eligibility.employment_task_available? }

    context "before 6 months from start date" do
      before { travel_to eligibility.start_date }

      it { is_expected.to be false }
    end

    context "exactly 6 months from start date" do
      before { travel_to eligibility.start_date + 6.months }

      it { is_expected.to be true }
    end

    context "after 6 months from start date" do
      before { travel_to eligibility.start_date + 6.months + 1.day }

      it { is_expected.to be true }
    end
  end

  describe "#approvable?" do
    subject { claim.eligibility }

    context "when employment task passed" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      before do
        claim.tasks.create!(name: "employment", passed: true)
      end

      it "returns truthy" do
        expect(subject).to be_approvable
      end
    end

    context "when employment task passed" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      before do
        claim.tasks.create!(name: "employment", passed: false)
      end

      it "returns false" do
        expect(subject).not_to be_approvable
      end
    end

    context "when no employment task persisted" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      it "returns falsey" do
        expect(subject).not_to be_approvable
      end
    end
  end
end
