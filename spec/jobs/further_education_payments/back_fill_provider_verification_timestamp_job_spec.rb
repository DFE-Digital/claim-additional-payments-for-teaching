require "rails_helper"

RSpec.describe FurtherEducationPayments::BackFillProviderVerificationTimestampJob, type: :job do
  let(:verification) do
    {
      "created_at" => "2024-01-01T12:00:00.000+00:00"
    }
  end

  it "does not change the dates for claims in the current academic year" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      verification: verification,
      provider_verification_completed_at: nil
    )

    claim = create(
      :claim,
      :further_education,
      academic_year: AcademicYear.current,
      eligibility: eligibility
    )

    expect { described_class.new.perform }
      .not_to change { eligibility.reload.provider_verification_completed_at }
      .from(nil)

    expect(claim.academic_year).to eq(AcademicYear.current)
  end

  it "back fills the dates for claims in the 2024/2025 academic year" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      verification: verification,
      provider_verification_completed_at: nil
    )

    create(
      :claim,
      :further_education,
      academic_year: AcademicYear.new(2024),
      eligibility: eligibility
    )

    expect { described_class.new.perform }
      .to change { eligibility.reload.provider_verification_completed_at }
      .from(nil)
      .to(Time.zone.parse("2024-01-01T12:00:00.000+00:00"))
  end
end
