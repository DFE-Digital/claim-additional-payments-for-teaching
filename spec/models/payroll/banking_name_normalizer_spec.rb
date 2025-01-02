require "rails_helper"

RSpec.describe Payroll::BankingNameNormalizer do
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

    context "name with leading and trailing spaces" do
      let(:name) { " John Doe " }
      it { is_expected.to eq "John Doe" }
    end

    context "name with spaces" do
      let(:name) { "Oscar Hernandez" }
      it { is_expected.to eq "Oscar Hernandez" }
    end

    context "name with multiple spaces" do
      let(:name) { "Chan Chiu Bruce" }
      it { is_expected.to eq "Chan Chiu Bruce" }
    end

    context "name with allowed characters" do
      let(:name) { "John &'()*,-./ Doe" }
      it { is_expected.to eq "John &'()*,-./ Doe" }
    end

    context "name with disallowed characters" do
      let(:name) { "John &'()*,-./+`%£^ Doe" }
      it { is_expected.to eq "John &'()*,-./ Doe" }
    end

    context "name that has it all" do
      let(:name) { "   John &'()*,-./+`%£^ Doe " }
      it { is_expected.to eq "John &'()*,-./ Doe" }
    end
  end
end
