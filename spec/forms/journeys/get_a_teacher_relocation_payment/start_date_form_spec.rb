require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::StartDateForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: multi_part_date_parms(option)
    )
  end

  def multi_part_date_parms(date)
    return {} unless date.present?

    {
      "start_date(1i)" => date.year.to_s,
      "start_date(2i)" => date.month.to_s,
      "start_date(3i)" => date.day.to_s
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
      let(:option) { nil }

      it { is_expected.not_to be_valid }
    end

    context "with a date in the future" do
      let(:option) { Date.tomorrow }

      it { is_expected.to be_valid }
    end

    context "with a date in the present" do
      let(:option) { Date.today }

      it { is_expected.to be_valid }
    end

    context "with a date in the past" do
      let(:option) { Date.yesterday }

      it { is_expected.to be_valid }
    end
  end

  describe "#start_date" do
    subject { form.start_date }

    before do
      journey_session.answers.assign_attributes(start_date: Date.tomorrow)
    end

    context "when date is not present in the params" do
      let(:option) { nil }

      it { is_expected.to eq(journey_session.answers.start_date) }
    end

    context "when date is present in the params" do
      let(:option) { Date.yesterday }

      it { is_expected.to eq(option) }
    end

    context "when date is invalid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            "start_date(1i)" => "01",
            "start_date(2i)" => "00",
            "start_date(3i)" => "2024"
          }
        )
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#save" do
    let(:option) { Date.tomorrow }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.start_date }
        .to(option)
      )
    end
  end
end
