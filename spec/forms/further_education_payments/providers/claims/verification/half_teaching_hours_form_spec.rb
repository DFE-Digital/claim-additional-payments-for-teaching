require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::HalfTeachingHoursForm, type: :model do
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
    context "when submission" do
      it do
        is_expected.not_to(
          allow_value(nil).for(:provider_verification_half_teaching_hours)
        )
      end

      it do
        is_expected.to(
          allow_value(true).for(:provider_verification_half_teaching_hours)
        )
      end

      it do
        is_expected.to(
          allow_value(false).for(:provider_verification_half_teaching_hours)
        )
      end
    end

    context "when saving progress" do
      before do
        allow(form).to receive(:save_and_exit?).and_return(true)
      end

      it do
        is_expected.to(
          allow_value(nil).for(:provider_verification_half_teaching_hours)
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_half_teaching_hours: true
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
          provider_verification_half_teaching_hours: true
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_verification_half_teaching_hours
        ).to be(true)
      end
    end

    context "when form is invalid" do
      let(:params) { {} }

      it "returns false" do
        expect(form.save).to be(false)
      end
    end
  end
end
