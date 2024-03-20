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
    let(:claim) { double }

    subject(:page_sequence) { described_class.page_sequence_for_claim(claim, completed_slugs, current_slug) }

    it { is_expected.to be_a(Journeys::PageSequence) }

    it "populates the page sequence attributes" do
      expect(page_sequence.claim).to eq(claim)
      expect(page_sequence.current_slug).to eq(current_slug)
      expect(page_sequence.completed_slugs).to eq(completed_slugs)
    end

    it "creates a slug sequence" do
      expect(Journeys::AdditionalPaymentsForTeaching::SlugSequence).to receive(:new).with(claim)
      page_sequence
    end
  end

  describe ".answers_presenter" do
    subject(:presenter) { described_class.answers_presenter }

    it { is_expected.to eq(Journeys::AdditionalPaymentsForTeaching::AnswersPresenter) }
  end
end
