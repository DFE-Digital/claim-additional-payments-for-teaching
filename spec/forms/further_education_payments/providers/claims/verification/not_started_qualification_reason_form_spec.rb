require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::NotStartedQualificationReasonForm, type: :model do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(:claim, :further_education, first_name: "Edna", surname: "Krabappel")
  end

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
      context "with no reasons selected" do
        let(:params) { {provider_verification_not_started_qualification_reasons: []} }

        it "is invalid" do
          expect(form).not_to be_valid

          expect(
            form.errors[:provider_verification_not_started_qualification_reasons]
          ).to include(
            "Select the reason or reasons why Edna Krabappel has not yet " \
            "started or completed a teaching qualification"
          )
        end
      end

      context "when other is selected" do
        context "with no other reason provided" do
          let(:params) do
            {
              provider_verification_not_started_qualification_reasons: ["other"]
            }
          end

          it "is invalid" do
            expect(form).not_to be_valid

            expect(
              form.errors[:provider_verification_not_started_qualification_reason_other]
            ).to include(
              "Enter the reason why Edna Krabappel has not yet started or " \
              "completed a teaching qualification"
            )
          end
        end
      end
    end

    context "when saving progress" do
      before do
        allow(form).to receive(:save_and_exit?).and_return(true)
      end

      context "with no reasons selected" do
        let(:params) { {} }

        it { is_expected.to be_valid }
      end

      context "with invalid reason" do
        let(:params) do
          {
            provider_verification_not_started_qualification_reasons: ["invalid_reason"]
          }
        end

        it "is invalid" do
          expect(form).not_to be_valid

          expect(
            form.errors[:provider_verification_not_started_qualification_reasons]
          ).to include(
            "Select the reason or reasons why Edna Krabappel has not yet " \
            "started or completed a teaching qualification"
          )
        end
      end
    end
  end
end
