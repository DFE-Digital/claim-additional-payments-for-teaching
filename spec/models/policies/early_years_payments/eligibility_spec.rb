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
      it do
        travel_to(eligibility.start_date) do
          is_expected.to be_falsey
        end
      end
    end

    context "exactly 6 months from start date" do
      it do
        travel_to(eligibility.start_date + 6.months - 2.hours) do
          is_expected.to be_falsey
        end
      end
    end

    context "after 6 months from start date" do
      it do
        travel_to(eligibility.start_date + 6.months + 2.hours) do
          is_expected.to be_truthy
        end
      end
    end
  end
end
