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
    described_class.new(answers: journey_session.answers, slug: "verify-claim")
  end

  describe "#failure_reason" do
    subject { authorisation.failure_reason }

    context "when the ukprns don't match" do
      let(:answers) do
        {
          dfe_sign_in_organisation_ukprn: "mismatch"
        }
      end

      it { is_expected.to eq(:organisation_mismatch) }
    end
  end
end
