require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::AdminTasksPresenter do
  it_behaves_like "ECP and LUP Combined Journey Admin Tasks Presenter", Policies::EarlyCareerPayments

  describe "#census_subjects_taught" do
    let(:claim) { build(:claim) }

    subject { described_class.new(claim) }

    context "when eligible_itt_subject is nil" do
      it "returns nil value" do
        expect(subject.census_subjects_taught).to eql([["Subject", nil]])
      end
    end
  end
end
