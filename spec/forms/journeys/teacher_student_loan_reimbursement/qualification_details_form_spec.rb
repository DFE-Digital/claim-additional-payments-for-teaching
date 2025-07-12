require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::QualificationDetailsForm do
  before { create(:journey_configuration, :student_loans) }

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        dqt_teacher_status: dqt_teacher_status
      }
    )
  end

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    let(:dqt_teacher_status) { {} }

    subject { form }

    describe "qualifications_details_check" do
      context "when `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: false}
          )
        end

        it { is_expected.to be_valid }
      end

      context "when not present" do
        let(:params) { ActionController::Parameters.new(claim: {}) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#dqt_qts_award_date" do
    let(:params) { ActionController::Parameters.new(claim: {}) }

    let(:dqt_teacher_status) do
      {
        qualified_teacher_status: {
          name: "Qualified teacher (trained)",
          qts_date: "2019-01-01"
        }
      }
    end

    subject { form.dqt_qts_award_date }

    it { is_expected.to eq AcademicYear.for(Date.new(2019, 1, 1)) }
  end

  describe "#save" do
    context "when invalid" do
      let(:dqt_teacher_status) { {} }

      let(:params) { ActionController::Parameters.new(claim: {}) }

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when valid" do
      context "when the qualifications_details_check is `false`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: false}
          )
        end

        let(:dqt_teacher_status) { {} }

        it "sets the qualifications_details_check to `false`" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.qualifications_details_check
            end.from(nil).to(false)
          )
        end

        it "sets qts_award_year as nil" do
          form.save

          expect(journey_session.reload.answers.qts_award_year).to eq nil
        end
      end

      context "when the qualifications_details_check is `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end

        context "when there is a dqt_teacher_record" do
          let(:dqt_teacher_status) do
            {
              trn: 123456,
              ni_number: "AB123123A",
              name: "Rick Sanchez",
              dob: "66-06-06T00:00:00",
              active_alert: false,
              state: 0,
              state_name: "Active",
              qualified_teacher_status: {
                name: "Qualified teacher (trained)",
                qts_date: qts_award_date,
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
          end

          context "when the dqt teacher record has a qts award date" do
            context "when the qts award date is eligible" do
              let(:qts_award_date) do
                Date.new(
                  Policies::StudentLoans.first_eligible_qts_award_year.start_year,
                  9,
                  1
                )
              end

              it "sets the qts_award_year to :on_or_after_cut_off_date" do
                expect { form.save }.to(
                  change do
                    journey_session.reload.answers.qts_award_year
                  end.from(nil).to("on_or_after_cut_off_date")
                )
              end

              it "sets the qualifications_details_check to `true`" do
                expect { form.save }.to(
                  change do
                    journey_session.reload.answers.qualifications_details_check
                  end.from(nil).to(true)
                )
              end
            end

            context "when the qts award date is not eligible" do
              let(:qts_award_date) do
                Date.new(
                  Policies::StudentLoans.first_eligible_qts_award_year.start_year,
                  1,
                  1
                )
              end

              it "sets the qts_award_year to :before_cut_off_date" do
                expect { form.save }.to(
                  change do
                    journey_session
                      .reload
                      .answers
                      .qts_award_year
                  end.from(nil).to("before_cut_off_date")
                )
              end

              it "sets the qualifications_details_check to `true`" do
                expect { form.save }.to(
                  change do
                    journey_session.reload.answers.qualifications_details_check
                  end.from(nil).to(true)
                )
              end
            end
          end

          context "when the dqt teacher record has no qts award date" do
            let(:qts_award_date) { nil }

            it "sets qts_award_year as nil" do
              form.save

              expect(journey_session.reload.answers.qts_award_year).to eq nil
            end

            it "sets the qualifications_details_check to `true`" do
              expect { form.save }.to(
                change do
                  journey_session.reload.answers.qualifications_details_check
                end.from(nil).to(true)
              )
            end
          end
        end

        context "when there is no dqt_teacher_record" do
          let(:dqt_teacher_status) { {} }

          it "sets qts_award_year as nil" do
            form.save

            expect(journey_session.reload.answers.qts_award_year).to eq nil
          end

          it "sets the qualifications_details_check to `true`" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.qualifications_details_check
              end.from(nil).to(true)
            )
          end
        end
      end
    end
  end
end
