require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::PassportForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:school) { create(:school) }
  let(:answers_hash) do
    {school_id: school.id}
  end
  let(:valid_passport) { nil }
  let(:passport_number) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        valid_passport:,
        passport_number:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:valid_passport)
        .with_message("Select yes if you have a valid passport")
      )
    end

    context "when no selected" do
      let(:valid_passport) { "false" }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when yes selected without passport number" do
      let(:valid_passport) { "true" }

      it "is not valid" do
        expect(subject).to be_invalid
      end
    end

    context "when yes selected with invalid passport number" do
      let(:valid_passport) { "true" }
      let(:passport_number) { "123" }

      it "is not valid" do
        expect(subject).to be_invalid
      end
    end

    context "when yes selected with valid passport number" do
      let(:valid_passport) { "true" }
      let(:passport_number) { "123456789" }

      it "is valid" do
        expect(subject).to be_valid
      end
    end
  end

  describe "#save" do
    let(:valid_passport) { "true" }
    let(:passport_number) { "123456789" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.valid_passport }.to(true)
        .and(change { journey_session.answers.passport_number }.to("123456789"))
      )
    end
  end
end
