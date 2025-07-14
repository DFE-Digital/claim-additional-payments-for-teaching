require "rails_helper"

RSpec.describe DfeSignIn::UserDataImporterJob do
  subject { described_class.new }

  it { expect(subject).to be_an(ApplicationJob) }

  describe "#perform" do
    context "when bypassed" do
      before do
        allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("review")
      end

      it "does not call importer" do
        expect(DfeSignIn::UserDataImporter).not_to receive(:new)

        subject.perform
      end
    end

    context "when not bypassed" do
      let(:importer) { double("DfeSignIn::User", run: true) }

      it "calls importer" do
        expect(DfeSignIn::UserDataImporter).to receive(:new).and_return(importer)

        subject.perform

        expect(importer).to have_received(:run)
      end
    end
  end
end
