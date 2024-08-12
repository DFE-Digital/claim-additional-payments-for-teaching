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
    before do
      allow(DfeSignIn::Api::User).to receive(:new).and_return(dfe_sign_in_user)
    end

    let(:dfe_sign_in_user) do
      instance_double(DfeSignIn::Api::User, service_access?: service_access)
    end

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

    context "with access to the service" do
      let(:service_access) { true }

      it "updates the session with the auth details from dfe signin" do
        expect { form.save! }.to(
          change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
            change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
              .from(nil)
              .to("12345678")
          ).and(
            change(journey_session.answers, :dfe_sign_in_organisation_id)
              .from(nil)
              .to("22222")
          ).and(
            change(journey_session.answers, :dfe_sign_in_service_access?)
              .from(false)
              .to(true)
          )
        )
      end
    end

    context "without access to the service" do
      let(:service_access) { false }

      it "sets the service access flag to false" do
        expect { form.save! }.to(
          change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
            change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
              .from(nil)
              .to("12345678")
          ).and(
            change(journey_session.answers, :dfe_sign_in_organisation_id)
              .from(nil)
              .to("22222")
          ).and(
            not_change(journey_session.answers, :dfe_sign_in_service_access?)
          )
        )
      end
    end
  end
end
