require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::EligibilityChecker do
  let(:eligible_ey_provider) do
    create(:eligible_ey_provider, max_claims: 2)
  end

  let(:journey_session) do
    create(
      :early_years_payment_provider_authenticated_session,
      answers: {
        nursery_urn: eligible_ey_provider.urn,
        academic_year: AcademicYear.new("2025/2026")
      }
    )
  end

  let(:eligibility_checker) do
    described_class.new(journey_session: journey_session)
  end

  describe "#ineligibility_reason" do
    subject { eligibility_checker.ineligibility_reason }

    describe "max_claim_exceeded" do
      before do
        # Previous academic year, not counted
        create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.new("2024/2025"),
          eligibility_attributes: {
            nursery_urn: eligible_ey_provider.urn
          },
          journey_session: create(:early_years_payment_provider_authenticated_session) # Different journey session
        )

        # approved claim, counted towards allowance
        create(
          :claim,
          :approved,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.new("2025/2026"),
          eligibility_attributes: {
            nursery_urn: eligible_ey_provider.urn
          },
          journey_session: create(:early_years_payment_provider_authenticated_session) # Different journey session
        )

        # rejected claim, not counted towards allowance
        create(
          :claim,
          :rejected,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.new("2025/2026"),
          eligibility_attributes: {
            nursery_urn: eligible_ey_provider.urn
          },
          journey_session: create(:early_years_payment_provider_authenticated_session) # Different journey session
        )

        # Claim belonging to the current journey session, not counted
        create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.new("2025/2026"),
          journeys_session_id: journey_session.id,
          eligibility_attributes: {
            nursery_urn: eligible_ey_provider.urn
          }
        )
      end

      context "when the number of claim is below the max" do
        it { is_expected.to be_nil }
      end

      context "when the number of claim is at the max" do
        before do
          create(
            :claim,
            policy: Policies::EarlyYearsPayments,
            academic_year: AcademicYear.new("2025/2026"),
            journey_session: create(:early_years_payment_provider_authenticated_session),
            eligibility_attributes: {
              nursery_urn: eligible_ey_provider.urn
            }
          )
        end

        it { is_expected.to eq(:max_claims_exceeded) }
      end
    end
  end
end
