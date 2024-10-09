require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::AdminTasksPresenter do
  describe "#employment" do
    let(:claim) { create(:claim, :submitted) }

    subject { described_class.new(claim) }

    it "displays answer with link" do
      expect(subject.employment[0][0]).to eql("Current provider")
      expect(subject.employment[0][1]).to include("href")
      expect(subject.employment[0][1]).to include(claim.school.dfe_number)
    end
  end
end
