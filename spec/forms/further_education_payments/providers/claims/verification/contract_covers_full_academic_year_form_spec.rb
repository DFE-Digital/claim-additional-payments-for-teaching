require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ContractCoversFullAcademicYearForm, type: :model do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:user) { create(:dfe_signin_user) }

  let(:claim) { create(:claim, :further_education) }

  let(:params) { {} }

  subject(:form) do
    described_class.new(
      claim: claim,
      user: user,
      params: params
    )
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(nil).for(
          :provider_verification_contract_covers_full_academic_year
        )
      )
    end
  end

  describe "#save" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_contract_covers_full_academic_year: true
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        eligibility = claim.eligibility.reload

        expect(
          eligibility.provider_verification_contract_covers_full_academic_year
        ).to be(true)
      end
    end
  end
end
