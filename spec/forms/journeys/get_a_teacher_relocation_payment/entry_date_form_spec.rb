require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::EntryDateForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: multi_part_date_parms(option)
    )
  end

  let(:option) { nil }

  def multi_part_date_parms(date)
    return {} unless date.present?

    {
      "date_of_entry(1i)" => date.year.to_s,
      "date_of_entry(2i)" => date.month.to_s,
      "date_of_entry(3i)" => date.day.to_s
    }
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    context "with an invalid date" do
      it { is_expected.not_to be_valid }
    end

    context "with a date in the future" do
      it do
        is_expected.not_to(
          allow_value(Date.tomorrow)
          .for(:date_of_entry)
          .with_message("Date of entry cannot be in the future")
        )
      end
    end

    context "with a date in the present" do
      it { is_expected.to allow_value(Date.today).for(:date_of_entry) }
    end

    context "with a date in the past" do
      it { is_expected.to allow_value(Date.yesterday).for(:date_of_entry) }
    end
  end

  describe "#date_of_entry" do
    subject { form.date_of_entry }

    before do
      journey_session.answers.assign_attributes(date_of_entry: Date.tomorrow)
    end

    context "when date is not present in the params" do
      let(:option) { nil }

      it { is_expected.to eq(journey_session.answers.date_of_entry) }
    end

    context "when date is persent in the params" do
      let(:option) { Date.yesterday }

      it { is_expected.to eq(option) }
    end

    context "when date is invalid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            "date_of_entry(1i)" => "01",
            "date_of_entry(2i)" => "00",
            "date_of_entry(3i)" => "2024"
          }
        )
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#save" do
    let(:option) { Date.yesterday }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.date_of_entry }
        .to(option)
      )
    end
  end
end
