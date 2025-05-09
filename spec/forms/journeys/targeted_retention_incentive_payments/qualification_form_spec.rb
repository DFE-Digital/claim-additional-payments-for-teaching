require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::QualificationForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        eligible_itt_subject: "mathematics", # reset if answers changed
        teaching_subject_now: true # reset if answers changed
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
      is_expected.to validate_inclusion_of(:qualification).in_array(
        %w[
          undergraduate_itt
          postgraduate_itt
          assessment_only
          overseas_recognition
        ]
      ).with_message("Select the route you took into teaching")
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
          qualification: "undergraduate_itt"
        }
      end

      context "when qualification has changed" do
        before do
          journey_session.answers.assign_attributes(
            qualification: "postgraduate_itt"
          )

          journey_session.save!
        end

        context "when qualifications_details_check is not true" do
          it "updates the session and resets the dependent answers" do
            expect { expect(form.save).to be(true) }.to(
              change { journey_session.reload.answers.qualification }
              .from("postgraduate_itt").to("undergraduate_itt")
              .and(
                change { journey_session.reload.answers.eligible_itt_subject }
                .from("mathematics").to(nil)
              )
              .and(
                change { journey_session.reload.answers.teaching_subject_now }
                .from(true).to(nil)
              )
            )
          end
        end

        context "when qualifications_details_check is true" do
          before do
            journey_session.answers.assign_attributes(
              qualifications_details_check: true
            )

            journey_session.save!
          end

          it "updates the session and does not reset the dependent answers" do
            expect { expect(form.save).to be(true) }.to(
              change { journey_session.reload.answers.qualification }
              .from("postgraduate_itt").to("undergraduate_itt")
              .and(
                not_change { journey_session.reload.answers.eligible_itt_subject }
              )
              .and(
                not_change { journey_session.reload.answers.teaching_subject_now }
              )
            )
          end
        end
      end

      context "when qualification has not changed" do
        before do
          journey_session.answers.assign_attributes(
            qualification: "undergraduate_itt"
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

  describe "#save!" do
    context "when valid" do
      let(:params) do
        {
          qualification: "undergraduate_itt"
        }
      end

      it "saves and returns true" do
        expect(form.save!).to be(true)
      end
    end

    context "when invalid" do
      it "raises an ActiveRecord::RecordInvalid error" do
        expect { form.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
