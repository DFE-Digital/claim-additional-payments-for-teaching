require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::OmniauthCallbackForm do
  let(:journey_session) do
    create(:further_education_payments_provider_session)
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      auth: auth
    )
  end

  describe "#save!" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        "uid" => "11111",
        "extra" => {
          "raw_info" => {
            "organisation" => {
              "id" => "22222",
              "ukprn" => "12345678"
            }
          }
        }
      )
    end

    it "updates the session with the auth details from dfe signin" do
      expect { form.save! }.to(
        change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
          change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
            .from(nil)
            .to("12345678")
        )
      )
    end
  end
end
