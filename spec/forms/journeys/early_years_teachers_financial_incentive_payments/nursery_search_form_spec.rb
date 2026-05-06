require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::NurserySearchForm, type: :model do
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
        allow_value("")
        .for(:nursery_search_query)
        .with_message("Search term must have a minimum of 3 characters")
      )
    end
  end

  describe "#results" do
    subject { form.results }

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
        name: "Test Nursery",
        address_line_1: "123 Test Street",
        address_line_2: "Test District",
        address_line_3: "Test City",
        town: "Test Town",
        postcode: "TE1 2ST"
      )
    end

    let(:provider_2) do
      create(
        :eligible_eytfi_provider,
        file_upload: file_upload,
        name: "Another Nursery",
        address_line_1: "456 Another Street",
        address_line_2: "Another District",
        address_line_3: "Another City",
        town: "Another Town",
        postcode: "AN1 2CD"
      )
    end

    before do
      provider_1
      provider_2
    end

    context "with a nursery name" do
      let(:params) { {nursery_search_query: "Test"} }

      it do
        is_expected.to match_array(
          [
            {
              id: provider_1.id,
              name: "Test Nursery",
              address: "123 Test Street, Test District, Test City, Test Town, TE1 2ST",
              closeDate: nil
            }
          ]
        )
      end
    end

    context "with a nursery postcode" do
      let(:params) { {nursery_search_query: "AN1 2CD"} }

      it do
        is_expected.to match_array(
          [
            {
              id: provider_2.id,
              name: "Another Nursery",
              address: "456 Another Street, Another District, Another City, Another Town, AN1 2CD",
              closeDate: nil
            }
          ]
        )
      end
    end
  end

  describe "#save" do
    subject { form.save }

    let(:nursery) { create(:eligible_eytfi_provider, name: "Test Nursery") }

    context "when invalid" do
      let(:params) do
        {
          nursery_search_query: nil,
          nursery_id: nil
        }
      end

      it { is_expected.to be(false) }
    end

    context "when valid" do
      context "when a nursery is selected" do
        let(:params) do
          {
            nursery_search_query: "Test",
            nursery_id: nursery.id.to_s
          }
        end

        it "sets the search query and nursery id in the session" do
          expect { expect(subject).to be(true) }.to(
            change { journey_session.reload.answers.nursery_search_query }
              .to("Test")
              .and(
                change { journey_session.reload.answers.nursery_id }
                  .to(nursery.id.to_s)
              )
          )
        end
      end

      context "when no nursery is selected" do
        let(:params) do
          {
            nursery_search_query: "Test",
            nursery_id: ""
          }
        end

        before do
          journey_session.answers.update!(nursery_id: "123")
        end

        it "sets the search query and clears the nursery id in the session" do
          expect { expect(subject).to be(true) }.to(
            change { journey_session.reload.answers.nursery_search_query }
              .to("Test")
              .and(change { journey_session.reload.answers.nursery_id }.to(nil))
          )
        end
      end
    end
  end
end
