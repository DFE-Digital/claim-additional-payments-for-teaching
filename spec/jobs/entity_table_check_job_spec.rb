require "rails_helper"

RSpec.describe DfE::Analytics::EntityTableCheckJob do
  describe "#perform" do
    it "runs the entity table check job" do
      expect_any_instance_of(DfE::Analytics::EntityTableCheckJob).to receive(:perform)

      DfE::Analytics::EntityTableCheckJob.new.perform
    end
  end
end
