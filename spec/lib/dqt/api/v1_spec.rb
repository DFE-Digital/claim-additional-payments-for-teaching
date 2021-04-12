require "rails_helper"

module Dqt
  class Api
    describe V1 do
      subject(:v1) { described_class.new(client: double("client")) }

      describe "#qualified_teaching_status" do
        it "returns QualifiedTeachingStatus" do
          expect(v1.qualified_teaching_status).to be_an_instance_of(described_class::QualifiedTeachingStatus)
        end

        it "memoizes QualifiedTeachingStatus" do
          expect(v1.qualified_teaching_status).to be(v1.qualified_teaching_status)
        end
      end
    end
  end
end
