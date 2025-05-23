require "rails_helper"

RSpec.describe Policies::ActiveRecordType do
  describe "#type" do
    it "returns :policy" do
      expect(subject.type).to eql(:policy)
    end
  end

  describe "#cast" do
    context "when string of policy" do
      it "returns constant" do
        expect(subject.cast("Policies::FurtherEducationPayments")).to eql(Policies::FurtherEducationPayments)
      end
    end

    context "when string that is not a policy" do
      it "returns constant" do
        expect(subject.cast("Foo")).to be_nil
      end
    end

    context "when a policy" do
      it "returns constant" do
        expect(subject.cast(Policies::FurtherEducationPayments)).to eql(Policies::FurtherEducationPayments)
      end
    end

    context "when a random constant" do
      it "returns constant" do
        expect(subject.cast(Object)).to be_nil
      end
    end
  end

  describe "#serialize" do
    it "converts constant to string" do
      expect(subject.serialize(Policies::FurtherEducationPayments)).to eql("Policies::FurtherEducationPayments")
    end

    it "converts string to string" do
      expect(subject.serialize("Policies::FurtherEducationPayments")).to eql("Policies::FurtherEducationPayments")
    end

    it "converts nil to nil" do
      expect(subject.serialize(nil)).to be_nil
    end
  end

  describe "#deserialize" do
    it "converts string to Policy" do
      expect(subject.deserialize("Policies::FurtherEducationPayments")).to eql(Policies::FurtherEducationPayments)
    end

    it "converts to nil when nil" do
      expect(subject.deserialize(nil)).to be_nil
    end
  end
end
