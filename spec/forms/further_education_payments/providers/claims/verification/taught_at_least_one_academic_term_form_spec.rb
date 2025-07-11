require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::TaughtAtLeastOneAcademicTermForm, type: :model do
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
          :provider_verification_taught_one_term_section_completed
        )
      )
    end

    context "when submission" do
      before do
        form.provider_verification_taught_one_term_section_completed = true
      end

      it do
        is_expected.not_to(
          allow_value(nil).for(
            :provider_verification_taught_at_least_one_academic_term
          )
        )
      end
    end

    context "when not submission" do
      before do
        form.provider_verification_taught_one_term_section_completed = false
      end

      it do
        is_expected.to(
          allow_value(nil).for(
            :provider_verification_taught_at_least_one_academic_term
          )
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_taught_at_least_one_academic_term: true,
          provider_verification_taught_one_term_section_completed: true
        }
      end

      it "returns false" do
        expect(form.incomplete?).to be(false)
      end
    end

    context "when form is invalid" do
      let(:params) { {} }

      it "returns true" do
        expect(form.incomplete?).to be(true)
      end
    end
  end

  describe "#save" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_taught_at_least_one_academic_term: true,
          provider_verification_taught_one_term_section_completed: true
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        eligibility = claim.eligibility

        expect(
          eligibility.provider_verification_taught_at_least_one_academic_term
        ).to be(true)

        expect(
          eligibility.provider_verification_taught_one_term_section_completed
        ).to be(true)
      end
    end
  end
end
