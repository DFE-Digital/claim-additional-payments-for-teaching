require "rails_helper"

RSpec.describe EntryDateStep, type: :model do
  subject(:step) { described_class.new(form) }

  context "teacher" do
    let(:form) { build(:teacher_form) }

    include_examples "behaves like a step",
                     described_class,
                     route_key: "entry-date",
                     required_fields: %i[date_of_entry],
                     question: "Enter the date you moved to England to start your teaching job",
                     question_type: :date
  end

  context "trainee" do
    let(:form) { build(:trainee_form) }

    include_examples "behaves like a step",
                     described_class,
                     route_key: "entry-date",
                     required_fields: %i[date_of_entry],
                     question: "Enter the date you moved to England to start your teacher training course",
                     question_type: :date
  end

  describe "additional validations" do
    describe "date_of_entry" do
      let(:form) { build(:form, date_of_entry:) }
      let(:error) { step.errors.messages_for(:date_of_entry) }

      before { step.valid? }

      context "when not in the future" do
        let(:date_of_entry) { 1.day.ago }

        it { expect(error).to be_blank }
      end

      context "when in the future" do
        let(:date_of_entry) { 1.day.from_now }

        it { expect(error).to be_present }
      end
    end
  end
end
