require "rails_helper"

RSpec.describe Payroll::NameNormalizer do
  describe ".normalize" do
    subject { described_class.normalize(name) }

    context "nil" do
      let(:name) { nil }
      it { is_expected.to be_nil }
    end

    context "empty string" do
      let(:name) { "" }
      it { is_expected.to eq "" }
    end

    context "blank string" do
      let(:name) { "   " }
      it { is_expected.to eq "" }
    end

    context "name with nothing to change" do
      let(:name) { "John" }
      it { is_expected.to eq "John" }
    end

    context "name curly quotes" do
      let(:name) { "O’Something" }
      it { is_expected.to eq "OSomething" }
    end

    context "name accents and spaces" do
      let(:name) { "Óscar Hernández" }
      it { is_expected.to eq "OscarHernandez" }
    end

    context "name with multiple spaces" do
      let(:name) { "Chan Chiu Bruce" }
      it { is_expected.to eq "ChanChiuBruce" }
    end

    context "name with emojis spaces" do
      let(:name) { "Thumbs 👍 Up " }
      it { is_expected.to eq "ThumbsUp" }
    end

    context "name with semi-colon" do
      let(:name) { "Samuel;" }
      it { is_expected.to eq "Samuel" }
    end

    context "name with hyphen" do
      let(:name) { "Double-Barrelled" }
      it { is_expected.to eq "DoubleBarrelled" }
    end

    context "name with a period" do
      let(:name) { "John. Smith" }
      it { is_expected.to eq "JohnSmith" }
    end

    context "name that has it all" do
      let(:name) { "Jámes'. Ryan, O’Hughes 👍" }
      it { is_expected.to eq "JamesRyanOHughes" }
    end
  end
end
