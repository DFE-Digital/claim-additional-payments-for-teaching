require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments, type: :model do
  it { is_expected.to include(BasePolicy) }

  it do
    expect(subject::VERIFIERS).to eq([
      AutomatedChecks::ClaimVerifiers::OneLoginIdentity,
      AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk,
      AutomatedChecks::ClaimVerifiers::FeRepeatApplicantCheck
    ])
  end

  specify {
    expect(subject).to have_attributes(
      notify_reply_to_id: "89939786-7078-4267-b197-ee505dfad8ae"
    )
  }
end
