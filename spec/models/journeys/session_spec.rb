require "rails_helper"

RSpec.describe Journeys::Session, type: :model do
  describe "validations" do
    describe "journey" do
      it { is_expected.to validate_presence_of(:journey) }

      it do
        is_expected.to(
          validate_inclusion_of(:journey).in_array(Journeys.all_routing_names)
        )
      end
    end
  end
end
