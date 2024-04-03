require "rails_helper"

RSpec.describe NqtInAcademicYearAfterIttForm, type: :model do
  before { create(:journey_configuration, :additional_payments) }

  let(:additional_payments_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  describe "validations" do
    let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

    describe "#nqt_in_academic_year_after_itt" do
      subject(:form) do
        described_class.new(
          journey: additional_payments_journey,
          claim: current_claim,
          params: params
        )
      end

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
    let(:form) do
      described_class.new(
        journey: journey,
        claim: current_claim,
        params: params
      )
    end

    before { form.save }

    context "when invalid" do
      let(:journey) { additional_payments_journey }

      let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

      let(:params) do
        ActionController::Parameters.new(
          claim: {
            nqt_in_academic_year_after_itt: nil
          }
        )
      end

      it "returns false" do
        expect { expect(form.save).to be false }.not_to(
          change { claim.eligibility.reload.nqt_in_academic_year_after_itt }
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

      context "when the current journey is not `additional-payments`" do
        let(:journey) { Journeys::TeacherStudentLoanReimbursement }

        let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

        it "sets the nqt_in_academic_year_after_itt attribute" do
          expect(claim.eligibility.nqt_in_academic_year_after_itt).to be true
        end

        it "does not set the induction as complete" do
          expect(claim.eligibility.induction_completed).to be nil
        end
      end

      context "when the current journey is `additional-payments`" do
        let(:journey) { additional_payments_journey }

        context "when the teacher has not passed the tid details check" do
          let(:claim) do
            create(
              :claim,
              :logged_in_with_tid,
              details_check: false,
              policy: Policies::EarlyCareerPayments
            )
          end

          it "sets the nqt_in_academic_year_after_itt attribute" do
            expect(claim.eligibility.nqt_in_academic_year_after_itt).to be true
          end

          it "does not set the induction as complete" do
            expect(claim.eligibility.induction_completed).to be nil
          end
        end

        context "when the teacher has passed the tid details check" do
          context "when there is not an eligible induction" do
            let(:claim) do
              create(
                :claim,
                :logged_in_with_tid,
                policy: Policies::EarlyCareerPayments,
                details_check: true,
                dqt_teacher_status: nil
              )
            end

            it "sets the nqt_in_academic_year_after_itt attribute" do
              expect(
                claim.eligibility.nqt_in_academic_year_after_itt
              ).to be true
            end

            it "does not set the induction as complete" do
              expect(claim.eligibility.induction_completed).to be nil
            end
          end

          context "when there is an eligible induction" do
            let(:claim) do
              create(
                :claim,
                :logged_in_with_tid,
                policy: Policies::EarlyCareerPayments,
                details_check: true,
                dqt_teacher_status: {
                  trn: 1234567,
                  ni_number: "AB123123A",
                  name: "Rick Sanchez",
                  dob: "66-06-06T00:00:00",
                  active_alert: false,
                  state: 0,
                  state_name: "Active",
                  qualified_teacher_status: {
                    name: "Qualified teacher (trained)",
                    qts_date: "2018-12-01",
                    state: 0,
                    state_name: "Active"
                  },
                  induction: {
                    start_date: "2021-07-01T00:00:00Z",
                    completion_date: "2021-07-05T00:00:00Z",
                    status: "Pass",
                    state: 0,
                    state_name: "Active"
                  },
                  initial_teacher_training: {
                    programme_start_date: "666-06-06T00:00:00",
                    programme_end_date: "2021-07-04T00:00:00Z",
                    programme_type: "Overseas Trained Teacher Programme",
                    result: "Pass",
                    subject1: "mathematics",
                    subject1_code: "G100",
                    subject2: nil,
                    subject2_code: nil,
                    subject3: nil,
                    subject3_code: nil,
                    qualification: "BA (Hons)",
                    state: 0,
                    state_name: "Active"
                  }
                }
              )
            end

            it "sets the nqt_in_academic_year_after_itt attribute" do
              expect(
                claim.eligibility.nqt_in_academic_year_after_itt
              ).to be true
            end

            it "sets the induction as complete" do
              expect(claim.eligibility.induction_completed).to be true
            end
          end
        end
      end
    end
  end

  describe "#backlink_path" do
    context "when the page sequence does not include 'correct-school'" do
      let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

      let(:form) do
        described_class.new(
          journey: additional_payments_journey,
          claim: current_claim,
          params: ActionController::Parameters.new({})
        )
      end

      subject(:backlink_path) { form.backlink_path }

      it { is_expected.to be_nil }
    end

    context "when the page sequence includes 'correct-school'" do
      before do
        tps_record = create(
          :teachers_pensions_service,
          :early_career_payments_matched_first,
          teacher_reference_number: "1234567",
          end_date: 1.year.from_now
        )

        local_authority = create(:local_authority, code: tps_record.la_urn)

        create(
          :school,
          :open,
          local_authority: local_authority,
          establishment_number: tps_record.school_urn
        )
      end

      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyCareerPayments,
          logged_in_with_tid: true,
          teacher_reference_number: "1234567"
        )
      end

      let(:form) do
        described_class.new(
          journey: additional_payments_journey,
          claim: current_claim,
          params: ActionController::Parameters.new({
            journey: "additional-payments"
          })
        )
      end

      subject(:backlink_path) { form.backlink_path }

      it { is_expected.to eq("/additional-payments/correct-school") }
    end
  end
end
