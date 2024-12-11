# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching do
  describe ".configuration" do
    context "with journey configuration record" do
      let!(:configuration) { create(:journey_configuration, :additional_payments) }

      it "returns the record" do
        expect(described_class.configuration).to eq(configuration)
      end
    end

    context "with no journey configuration record" do
      it "raises an exception" do
        expect { described_class.configuration }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".start_page_url" do
    before { allow(Journeys::AdditionalPaymentsForTeaching::SlugSequence).to receive(:start_page_url).and_return("test") }

    it "returns the slug sequence start_page_url" do
      expect(described_class.start_page_url).to eq("test")
    end
  end

  describe ".slug_sequence" do
    subject(:slug) { described_class.slug_sequence }

    it { is_expected.to eq(Journeys::AdditionalPaymentsForTeaching::SlugSequence) }
  end

  describe ".page_sequence_for_claim" do
    let(:completed_slugs) { [:test] }
    let(:current_slug) { [:test2] }
    let(:journey_session) { build(:additional_payments_session) }

    subject(:page_sequence) do
      described_class.page_sequence_for_claim(
        journey_session,
        completed_slugs,
        current_slug
      )
    end

    it { is_expected.to be_a(Journeys::PageSequence) }

    it "populates the page sequence attributes" do
      expect(page_sequence.current_slug).to eq(current_slug)
      expect(page_sequence.completed_slugs).to eq(completed_slugs)
    end

    it "creates a slug sequence" do
      expect(Journeys::AdditionalPaymentsForTeaching::SlugSequence).to(
        receive(:new).with(journey_session)
      )
      page_sequence
    end
  end

  describe ".answers_presenter" do
    subject(:presenter) { described_class.answers_presenter }

    it { is_expected.to eq(Journeys::AdditionalPaymentsForTeaching::AnswersPresenter) }
  end

  shared_examples "true for years" do |start_years_range, policy_year|
    Journeys::AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(policy_year).each do |itt_academic_year|
      context "ITT year #{itt_academic_year}" do
        let(:itt_academic_year) { itt_academic_year }

        if start_years_range.include?(itt_academic_year.start_year)
          it { is_expected.to be true }
        else
          it { is_expected.to be false }
        end
      end
    end
  end

  shared_examples "false for all years" do |policy_year|
    Journeys::AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(policy_year).each do |itt_academic_year|
      context "ITT year #{itt_academic_year}" do
        let(:itt_academic_year) { itt_academic_year }

        it { is_expected.to be false }
      end
    end
  end

  describe ".set_a_reminder?" do
    subject { described_class.set_a_reminder?(itt_academic_year: itt_academic_year, policy: policy) }
    let(:policy) { Policies::EarlyCareerPayments }
    let!(:configuration) { create(:journey_configuration, :additional_payments, current_academic_year: policy_year) }

    context "Claim year: 22/23" do
      let(:policy_year) { AcademicYear.new(2022) }

      # 2017 is eligible now - but falls out of the 5 year window next year
      it_behaves_like "true for years", 2018..2021, AcademicYear.new(2022)
    end

    context "Claim year: 23/24" do
      let(:policy_year) { AcademicYear.new(2023) }

      # 2018 is eligible now - but falls out of the 5 year window next year
      it_behaves_like "true for years", 2019..2022, AcademicYear.new(2023)
    end

    context "Claim year: 24/25" do
      let(:policy_year) { AcademicYear.new(2024) }

      context "Last year of the policy - ECP policy" do
        let(:policy) { Policies::EarlyCareerPayments }

        # ECP will be removed after 2024/2025 academic year
        it_behaves_like "false for all years", AcademicYear.new(2024)
      end

      context "LUP policy" do
        let(:policy) { Policies::LevellingUpPremiumPayments }

        # 2019 is eligible now - but falls out of the 5 year window next year
        it_behaves_like "true for years", 2020..2023, AcademicYear.new(2024)
      end
    end
  end
end
