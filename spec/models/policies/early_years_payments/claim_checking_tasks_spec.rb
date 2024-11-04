require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::ClaimCheckingTasks do
  let(:claim) do
    build(
      :claim,
      policy: Policies::EarlyYearsPayments
    )
  end

  subject { described_class.new(claim) }

  describe "#applicable_task_names" do
    it "includes employment task" do
      expect(subject.applicable_task_names).to include("employment")
    end
  end
end
