require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ContractTypeForm, type: :model do
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
        is_expected.to(
          validate_inclusion_of(:provider_verification_contract_type)
            .in_array(%w[permanent fixed_term variable_hours])
            .with_message(
              "Select the type of contract #{form.claimant_name} has directly " \
              "with #{form.provider_name}"
            )
        )
      end
    end

    context "when saving progress" do
      before do
        allow(form).to receive(:save_and_exit?).and_return(true)
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_contract_type)
            .in_array(["permanent", "fixed_term", "variable_hours", nil])
            .with_message(
              "Select the type of contract #{form.claimant_name} has directly " \
              "with #{form.provider_name}"
            )
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_contract_type: "permanent"
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
          provider_verification_contract_type: "permanent"
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_verification_contract_type
        ).to eq("permanent")
      end

      context "when provider_verification_started_at is nil" do
        before do
          claim.eligibility.update!(
            provider_verification_started_at: nil,
            provider_assigned_to_id: nil
          )
        end

        it "sets provider_verification_started_at" do
          expect { form.save }.to change {
            claim.eligibility.reload.provider_verification_started_at
          }.from(nil).to(be_present)
        end

        it "creates an event" do
          expect { form.save }.to change {
            Event.where(name: "claim_fe_provider_verification_started").count
          }.by(1)
        end

        it "sets provider_assigned_to_id to the current user" do
          expect { form.save }.to change {
            claim.eligibility.reload.provider_assigned_to_id
          }.from(nil).to(user.id)
        end
      end

      context "when provider_verification_started_at is already set" do
        let(:original_timestamp) { 1.hour.ago }
        let(:original_user) { create(:dfe_signin_user) }

        before do
          claim.eligibility.update!(
            provider_verification_started_at: original_timestamp,
            provider_assigned_to_id: original_user.id
          )
        end

        it "does not change provider_verification_started_at" do
          expect { form.save }.not_to change {
            claim.eligibility.reload.provider_verification_started_at
          }
        end

        it "does not change provider_assigned_to_id" do
          expect { form.save }.not_to change {
            claim.eligibility.reload.provider_assigned_to_id
          }
        end
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
