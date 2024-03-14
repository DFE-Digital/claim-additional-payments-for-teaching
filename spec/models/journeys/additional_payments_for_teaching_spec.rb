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
end
