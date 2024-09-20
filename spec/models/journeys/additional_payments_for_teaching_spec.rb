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

  describe ".set_a_reminder?" do
    subject { described_class.set_a_reminder?(itt_academic_year: itt_academic_year, policy_year: policy_year) }
    let(:itt_academic_year) { AcademicYear.new(year) }

    context "Claim year: 22/23" do
      let(:policy_year) { AcademicYear.new(2022) }

      # Eligible now - but falls out of 5 year window next year so don't set a reminder
      context "ITT year: 17/18" do
        let(:year) { 2017 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 18/19" do
        let(:year) { 2018 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be true }
      end
    end

    context "Claim year: 23/24" do
      let(:policy_year) { AcademicYear.new(2023) }

      # Eligible now - but falls out of 5 year window next year so don't set a reminder
      context "ITT year: 18/19" do
        let(:year) { 2018 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be true }
      end

      context "ITT year: 22/23" do
        let(:year) { 2022 }

        specify { expect(subject).to be true }
      end
    end

    # Last policy year - no reminders to set
    context "Claim year: 24/25" do
      let(:policy_year) { AcademicYear.new(2024) }

      context "ITT year: 19/20" do
        let(:year) { 2019 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 20/21" do
        let(:year) { 2020 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 21/22" do
        let(:year) { 2021 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 22/23" do
        let(:year) { 2022 }

        specify { expect(subject).to be false }
      end

      context "ITT year: 23/24" do
        let(:year) { 2023 }

        specify { expect(subject).to be false }
      end
    end
  end
end
