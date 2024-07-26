# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::SessionAnswersType do
  describe "#cast_value" do
    subject { described_class.new.cast_value(json) }

    let(:json) { {"current_school_id" => current_school_id}.to_json }
    let(:current_school_id) { "some-id" }

    context "with a value that contains attributes that exist on the answers class" do
      it "has the expected attributes" do
        expect(subject.current_school_id).to eq current_school_id
      end
    end

    context "with a value that contains attributes that no longer exist on the answers class" do
      let(:json) { {"current_school_id" => "some-id", "attribute-that-no-longer-exists" => "some-value"}.to_json }

      it "has the expected attributes" do
        expect(subject.current_school_id).to eq current_school_id
      end
    end

    context "with an empty string" do
      let(:json) { "" }

      it { is_expected.to be_nil }
    end
  end
end
