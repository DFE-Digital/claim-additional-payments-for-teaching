require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::EligibleIttSubjectForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        itt_academic_year: AcademicYear.current.to_s, # used to determine eligible subjects
        teaching_subject_now: true, # reset if answers changed
        eligible_degree_subject: true # reset if answers changed
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
      is_expected.to validate_inclusion_of(:eligible_itt_subject).in_array(
        [:chemistry, :computing, :mathematics, :physics]
      ).with_message("Select a subject")
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
          eligible_itt_subject: "mathematics"
        }
      end

      context "when eligible_itt_subject has changed" do
        before do
          journey_session.answers.assign_attributes(
            eligible_itt_subject: "chemistry"
          )

          journey_session.save!
        end

        context "when qualifications_details_check is not true" do
          it "updates the session and resets the dependent answers" do
            expect { expect(form.save).to be(true) }.to(
              change { journey_session.reload.answers.eligible_itt_subject }
              .from("chemistry").to("mathematics")
              .and(
                change { journey_session.reload.answers.teaching_subject_now }
                .from(true).to(nil)
              )
              .and(
                change { journey_session.reload.answers.eligible_degree_subject }
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
              change { journey_session.reload.answers.eligible_itt_subject }
              .from("chemistry").to("mathematics")
              .and(
                not_change { journey_session.reload.answers.teaching_subject_now }
              )
              .and(
                not_change { journey_session.reload.answers.eligible_degree_subject }
              )
            )
          end
        end
      end

      context "when eligible_itt_subject has not changed" do
        before do
          journey_session.answers.assign_attributes(
            eligible_itt_subject: "mathematics"
          )

          journey_session.save!
        end

        it "updates the session and does not reset the dependent answers" do
          expect { expect(form.save).to be(true) }.to(
            not_change { journey_session.reload.answers.eligible_itt_subject }
            .from("mathematics")
            .and(
              not_change { journey_session.reload.answers.teaching_subject_now }
            )
            .and(
              not_change { journey_session.reload.answers.eligible_degree_subject }
            )
          )
        end
      end
    end
  end
end
