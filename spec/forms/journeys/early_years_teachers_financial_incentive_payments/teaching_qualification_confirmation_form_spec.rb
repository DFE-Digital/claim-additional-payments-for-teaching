require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::TeachingQualificationConfirmationForm, type: :model do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )
  end

  let(:journey) { Journeys::EarlyYearsTeachersFinancialIncentivePayments }
  let(:journey_session) do
    create(:early_years_teachers_financial_incentive_payments_session)
  end

  let(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    let(:params) { {} }

    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:teaching_qualification_confirmation)
        .with_message("Select whether or not you hold a relevant teaching qualification")
      )
    end
  end

  describe "#radio_options" do
    subject { form.radio_options }

    let(:params) { {} }

    it do
      is_expected.to match([
        an_object_having_attributes(id: true, name: "Yes"),
        an_object_having_attributes(id: false, name: "No")
      ])
    end
  end

  describe "#save" do
    subject { form.save }

    context "when invalid" do
      let(:params) { {teaching_qualification_confirmation: nil} }

      it { is_expected.to be(false) }
    end

    context "when valid" do
      context "when true is selected" do
        let(:params) { {teaching_qualification_confirmation: "true"} }

        it "sets teaching_qualification_confirmation to true in the session" do
          expect { expect(subject).to be(true) }.to(
            change { journey_session.reload.answers.teaching_qualification_confirmation }
              .to(true)
          )
        end
      end

      context "when false is selected" do
        let(:params) { {teaching_qualification_confirmation: "false"} }

        it "sets teaching_qualification_confirmation to false in the session" do
          expect { expect(subject).to be(true) }.to(
            change { journey_session.reload.answers.teaching_qualification_confirmation }
              .to(false)
          )
        end
      end
    end
  end

  describe "#completed?" do
    subject { form.completed? }

    let(:params) { {} }

    context "when teaching_qualification_confirmation is true in the session" do
      before do
        journey_session.answers.update!(teaching_qualification_confirmation: true)
      end

      it { is_expected.to be(true) }
    end

    context "when teaching_qualification_confirmation is false in the session" do
      before do
        journey_session.answers.update!(teaching_qualification_confirmation: false)
      end

      it { is_expected.to be(true) }
    end

    context "when teaching_qualification_confirmation is nil in the session" do
      it { is_expected.to be(false) }
    end
  end
end
