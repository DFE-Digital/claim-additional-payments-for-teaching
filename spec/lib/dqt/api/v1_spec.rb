require "rails_helper"

module Dqt
  class Api
    describe V1 do
      subject(:v1) { described_class.new(client: double("client")) }

      describe "#qualified_teaching_statuses" do
        subject(:qualified_teaching_statuses) { v1.qualified_teaching_statuses }

        it "returns QualifiedTeachingStatuses" do
          expect(qualified_teaching_statuses).to be_an_instance_of(described_class::QualifiedTeachingStatuses)
        end

        it "memoizes QualifiedTeachingStatus" do
          expect(qualified_teaching_statuses).to be(qualified_teaching_statuses)
        end
      end
    end
  end
end
