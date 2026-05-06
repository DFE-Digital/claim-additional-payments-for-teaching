require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::NurserySelectForm, type: :model do
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
        .for(:nursery_id)
        .with_message("Select the setting you work in")
      )
    end
  end

  describe "#radio_options" do
    subject { form.radio_options }

    let(:params) { {} }

    let(:file_upload) do
      create(
        :file_upload,
        :with_current_academic_year,
        target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
      )
    end

    let(:provider_1) do
      create(
        :eligible_eytfi_provider,
        file_upload: file_upload,
        name: "Test Nursery"
      )
    end

    let(:provider_2) do
      create(
        :eligible_eytfi_provider,
        file_upload: file_upload,
        name: "Another Nursery"
      )
    end

    before do
      provider_1
      provider_2
      journey_session.answers.update!(nursery_search_query: "Test")
    end

    it { is_expected.to match_array([provider_1]) }
  end

  describe "#save" do
    subject { form.save }

    let(:nursery) { create(:eligible_eytfi_provider, name: "Test Nursery") }

    context "when invalid" do
      let(:params) { {nursery_id: nil} }

      it { is_expected.to be(false) }
    end

    context "when valid" do
      let(:params) { {nursery_id: nursery.id.to_s} }

      it "sets the nursery id in the session" do
        expect { expect(subject).to be(true) }.to(
          change { journey_session.reload.answers.nursery_id }
            .to(nursery.id.to_s)
        )
      end
    end
  end

  describe "#completed?" do
    subject { form.completed? }

    let(:params) { {} }

    context "when nursery_id is present in the session" do
      before do
        journey_session.answers.update!(nursery_id: "123")
      end

      it { is_expected.to be(true) }
    end

    context "when nursery_id is not present in the session" do
      it { is_expected.to be(false) }
    end
  end
end
