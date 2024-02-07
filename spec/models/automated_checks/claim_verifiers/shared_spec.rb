require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::Shared do
  let(:mock_class) do
    Class.new do
      include AutomatedChecks::ClaimVerifiers::Shared
    end
  end

  it do
    expect(mock_class::VERIFIERS).to eq([
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment
    ])
  end
end
