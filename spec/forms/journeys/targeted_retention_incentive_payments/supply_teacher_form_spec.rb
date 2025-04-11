require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::SupplyTeacherForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        has_entire_term_contract: true, # reset if answers changed
        employed_directly: true # reset if answers changed
      }
    )
  end

  let(:params) do
    {}
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil).for(:employed_as_supply_teacher).with_message(
          "Select yes if you are a supply teacher"
        )
      )
    end
  end

  describe "#save" do
    context "when invalid" do
      it "returns false and does not save the journey session" do
        expect { expect(form.save).to be(false) }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end

    context "when valid" do
      let(:params) do
        {
          employed_as_supply_teacher: "true"
        }
      end

      context "when employed_as_supply_teacher has changed" do
        before do
          journey_session.answers.assign_attributes(
            employed_as_supply_teacher: false
          )

          journey_session.save!
        end

        it "updates the session and resets the dependent answers" do
          expect { expect(form.save).to be(true) }.to(
            change { journey_session.reload.answers.employed_as_supply_teacher }
            .from(false).to(true)
            .and(
              change { journey_session.reload.answers.has_entire_term_contract }
              .from(true).to(nil)
            )
            .and(
              change { journey_session.reload.answers.employed_directly }
              .from(true).to(nil)
            )
          )
        end
      end

      context "when employed_as_supply_teacher has not changed" do
        before do
          journey_session.answers.assign_attributes(
            employed_as_supply_teacher: true
          )

          journey_session.save!
        end

        it "returns true and does not modify the journey session" do
          expect { expect(form.save).to be(true) }.to(
            not_change { journey_session.reload.answers.attributes }
          )
        end
      end
    end
  end
end
