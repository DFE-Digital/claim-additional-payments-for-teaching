require "rails_helper"

RSpec.describe SignInForm do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) do
    build(
      :"#{journey::I18N_NAMESPACE}_session",
      answers: attributes_for(
        :"#{journey::I18N_NAMESPACE}_answers",
        :with_details_from_onelogin
      )
    )
  end

  subject(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  let(:params) do
    ActionController::Parameters.new
  end

  describe "#save" do
    it "returns true" do
      expect(subject.save).to be_truthy
    end
  end
end
