require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::Authorisation do
  let(:eligibility) { create(:further_education_payments_eligibility) }

  let(:organisation) { eligibility.school }

  let(:claim) { eligibility.claim }

  let(:journey_session) do
    create(
      :further_education_payments_provider_session,
      answers: answers.merge(claim_id: claim.id)
    )
  end

  let(:authorisation) do
    described_class.new(answers: journey_session.answers)
  end

  describe "#failure_reason" do
    subject { authorisation.failure_reason }

    context "when the ukprns don't match" do
      let(:answers) do
        {
          dfe_sign_in_service_access: true,
          dfe_sign_in_organisation_ukprn: "mismatch"
        }
      end

      it { is_expected.to eq(:organisation_mismatch) }
    end

    context "when the user does not have access to the service" do
      let(:answers) do
        {
          dfe_sign_in_service_access: false,
          dfe_sign_in_organisation_ukprn: organisation.ukprn
        }
      end

      it { is_expected.to eq(:no_service_access) }
    end

    context "when the user does not have the required role" do
      let(:answers) do
        {
          dfe_sign_in_service_access: true,
          dfe_sign_in_organisation_ukprn: organisation.ukprn,
          dfe_sign_in_role_codes: ["incorrect_role"]
        }
      end

      it { is_expected.to eq(:incorrect_role) }
    end

    context "when the user is a claim admin" do
      let(:answers) do
        {
          dfe_sign_in_service_access: true,
          dfe_sign_in_organisation_ukprn: organisation.ukprn,
          dfe_sign_in_role_codes: [
            DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
            Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
          ]
        }
      end

      it { is_expected.to eq(:claim_admin) }
    end
  end
end
