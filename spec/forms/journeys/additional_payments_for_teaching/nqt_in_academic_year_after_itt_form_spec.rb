require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::NqtInAcademicYearAfterIttForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) do
    create(:additional_payments_session, answers: answers)
  end

  subject(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    let(:answers) { {} }

    describe "#nqt_in_academic_year_after_itt" do
      context "when `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              nqt_in_academic_year_after_itt: true
            }
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              nqt_in_academic_year_after_itt: false
            }
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `nil`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {
              nqt_in_academic_year_after_itt: nil
            }
          )
        end

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#save" do
    before { form.save }

    context "when invalid" do
      let(:answers) { {} }

      let(:params) do
        ActionController::Parameters.new(
          claim: {
            nqt_in_academic_year_after_itt: nil
          }
        )
      end

      it "returns false" do
        expect { expect(form.save).to be false }.not_to(
          change { journey_session.answers.nqt_in_academic_year_after_itt }
        )
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            nqt_in_academic_year_after_itt: true
          }
        )
      end

      describe "nqt_in_academic_year_after_itt" do
        let(:answers) { {} }

        it "sets the value on the journey session" do
          expect(journey_session.answers.nqt_in_academic_year_after_itt).to be true
        end
      end

      describe "induction_completed" do
        context "when the teacher has not passed the tid details check" do
          let(:answers) do
            {
              logged_in_with_tid: true,
              details_check: false
            }
          end

          it "does not set the induction as complete" do
            expect(journey_session.reload.answers.induction_completed).to be nil
          end
        end

        context "when the teacher has passed the tid details check" do
          context "when there is not an eligible induction" do
            let(:answers) do
              {
                details_check: true,
                logged_in_with_tid: true,
                dqt_teacher_status: nil
              }
            end

            it "does not set the induction as complete" do
              expect(journey_session.reload.answers.induction_completed).to be nil
            end
          end

          context "when there is an eligible induction" do
            let(:answers) do
              {
                details_check: true,
                logged_in_with_tid: true
              }.merge(
                attributes_for(:claim, :with_dqt_teacher_status)
                .except(:started_at, :reference)
              )
            end

            it "sets the induction as complete" do
              expect(journey_session.reload.answers.induction_completed).to be true
            end
          end
        end
      end

      describe "qualification" do
        let(:answers) { {} }

        context "when the claim is not from a trainee teacher" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {
                nqt_in_academic_year_after_itt: true
              }
            )
          end

          it "does not set the qualification" do
            expect(journey_session.reload.answers.qualification).to be nil
          end
        end

        context "when the claim is from a trainee teacher" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {
                nqt_in_academic_year_after_itt: false
              }
            )
          end

          it "sets the qualification and resets dependent answers" do
            expect(
              journey_session.answers.qualification
            ).to eq "postgraduate_itt"
          end
        end
      end
    end
  end
end
