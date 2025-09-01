require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ClaimantEmploymentCheckDeclarationForm, type: :model do
  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(:claim, :further_education)
  end

  let(:params) do
    {}
  end

  subject(:form) do
    described_class.new(
      claim: claim,
      user: user,
      params: params
    )
  end

  describe "validations" do
    it do
      is_expected.to validate_presence_of(
        :provider_verification_claimant_employment_check_declaration
      ).with_message(
        "Tick the box to declare that the information provided in this form " \
        "is correct"
      )
    end
  end
end
