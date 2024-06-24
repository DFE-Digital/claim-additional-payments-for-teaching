require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::FurtherEducationProvisionSearchForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        provision_search:
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
    let(:provision_search) { "" }

    it do
      is_expected.not_to(
        allow_value("")
        .for(:provision_search)
        .with_message("Enter a college name or postcode")
      )
    end
  end

  describe "#save" do
    let(:provision_search) { "city college plymouth" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.provision_search }.to(provision_search)
      )
    end
  end
end
