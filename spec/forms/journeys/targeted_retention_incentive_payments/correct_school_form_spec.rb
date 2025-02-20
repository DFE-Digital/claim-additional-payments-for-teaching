require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::CorrectSchoolForm, type: :model do
  before { FeatureFlag.enable!(:tri_only_journey) }

  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments_only
    )
  end

  let(:local_authority) { create(:local_authority) }

  let(:school) do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      local_authority: local_authority,
      targeted_retention_incentive_payments_award_amount: 2_000
    )
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        teacher_id_user_info: {
          trn: "1234567"
        }
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

  before do
    # Create a TPS record so recent_tps_school returns the school
    create(
      :teachers_pensions_service,
      start_date: journey_session.created_at - 1.day,
      end_date: 1.year.from_now,
      teacher_reference_number: journey_session.answers.teacher_id_user_info["trn"],
      school_urn: school.establishment_number,
      la_urn: local_authority.code
    )
  end

  describe "#initialize" do
    describe "confirm_recent_tps_school" do
      subject { form.confirm_recent_tps_school }

      context "when params are empty" do
        context "when a recent tps school was not chosen" do
          before do
            journey_session.answers.assign_attributes(
              school_somewhere_else: true
            )

            journey_session.save!
          end

          it { is_expected.to be true }
        end

        context "when a recent tps school was chosen" do
          before do
            journey_session.answers.assign_attributes(
              school_somewhere_else: false
            )

            journey_session.save!
          end

          it { is_expected.to be false }
        end
      end

      context "when params are present" do
        let(:params) do
          {
            confirm_recent_tps_school: nil
          }
        end

        it { is_expected.to be nil }
      end
    end
  end

  describe "validations" do
    subject { form }

    it { is_expected.not_to(allow_value(nil).for(:confirm_recent_tps_school)) }
  end

  describe "#save" do
    context "when invalid" do
      let(:params) do
        {
          confirm_recent_tps_school: nil
        }
      end

      it "returns false and does not save the journey session" do
        expect { expect(form.save).to be(false) }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end

    context "when valid" do
      context "when the school is confirmed" do
        let(:params) do
          {
            confirm_recent_tps_school: true
          }
        end

        it "updates the session" do
          expect { expect(form.save).to be(true) }.to(
            change { journey_session.reload.answers.current_school_id }
            .from(nil).to(school.id)
            .and(change { journey_session.reload.answers.school_somewhere_else }
            .from(nil).to(false))
            .and(change { journey_session.reload.answers.award_amount }
            .from(nil).to(2_000))
          )
        end
      end

      context "when the school is not confirmed" do
        let(:params) do
          {
            confirm_recent_tps_school: false
          }
        end

        it "updates the session" do
          expect { expect(form.save).to be(true) }.to(
            change { journey_session.reload.answers.current_school_id }
            .from(nil).to("somewhere_else")
            .and(change { journey_session.reload.answers.school_somewhere_else }
            .from(nil).to(true))
          )
        end
      end
    end
  end
end
