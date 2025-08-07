require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ClaimantEmployedByCollegeForm, type: :model do
  let(:user) { create(:dfe_signin_user) }

  let(:school) do
    create(:school, name: "Springfield College")
  end

  let(:claim) do
    create(
      :claim,
      :further_education,
      first_name: "Edna",
      surname: "Krabappel",
      eligibility_attributes: {
        school: school
      }
    )
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
      is_expected.not_to allow_value(nil).for(
        :provider_verification_claimant_employed_by_college
      ).with_message(
        "Select yes if Springfield College employs Edna Krabappel"
      )
    end
  end
end
