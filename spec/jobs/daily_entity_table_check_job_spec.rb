require "rails_helper"

RSpec.describe DailyEntityTableCheckJob do
  describe "#perform" do
    it "runs the entity table check job" do
      expect_any_instance_of(DfE::Analytics::EntityTableCheckJob).to receive(:perform)

      DailyEntityTableCheckJob.new.perform
    end
  end
end
