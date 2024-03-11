require "rails_helper"

RSpec.describe StartDateStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "start-date",
                   required_fields: %i[start_date],
                   question: "Enter the start date of your contract",
                   question_type: :date

  describe "additional validations" do
    describe "start_date" do
      let(:form) { build(:form, start_date:) }
      let(:error) { step.errors.messages_for(:start_date) }

      before { step.valid? }

      context "when not in the future" do
        let(:start_date) { 1.day.ago }

        it { expect(error).to be_blank }
      end

      context "when in the future" do
        let(:start_date) { 1.day.from_now }

        it { expect(error).to be_present }
      end
    end
  end
end
