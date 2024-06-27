require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::StartDateForm, type: :model do
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
      it { is_expected.not_to be_valid }
    end

    context "with a date in the future" do
      it do
        is_expected.not_to(
          allow_value(Date.tomorrow)
          .for(:start_date)
          .with_message("Start date cannot be in the future")
        )
      end
    end

    context "with a date in the present" do
      it { is_expected.to allow_value(Date.today).for(:start_date) }
    end

    context "with a date in the past" do
      it { is_expected.to allow_value(Date.yesterday).for(:start_date) }
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
    let(:option) { Date.yesterday }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.start_date }
        .to(option)
      )
    end

    describe "resetting depenent answers" do
      before do
        journey_session.answers.assign_attributes(date_of_entry: 1.year.ago)
        journey_session.save!
      end

      context "when the start date is changed" do
        it "resets the dependent answers" do
          expect { form.save }.to(
            change { journey_session.reload.answers.date_of_entry }
            .to(nil)
          )
        end
      end

      context "when the start date is not changed" do
        before do
          journey_session.answers.assign_attributes(start_date: option)
          journey_session.save!
        end

        it "does not reset the dependent answers" do
          expect { form.save }.to(
            not_change { journey_session.reload.answers.date_of_entry }
          )
        end
      end
    end
  end
end
