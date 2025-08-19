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

  describe "#save" do
    context "when not employed by college" do
      let(:params) do
        {
          provider_verification_claimant_employed_by_college: false
        }
      end

      it "calls alternative IDV completed hook" do
        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        expect(form.save).to be true

        expect(Policies::FurtherEducationPayments).to have_received(
          :alternative_idv_completed!
        ).with(claim)
      end
    end

    context "when employed by college" do
      let(:params) do
        {
          provider_verification_claimant_employed_by_college: true
        }
      end

      it "does not call alternative IDV completed hook" do
        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        expect(form.save).to be true

        expect(Policies::FurtherEducationPayments).not_to have_received(
          :alternative_idv_completed!
        )
      end
    end
  end
end
