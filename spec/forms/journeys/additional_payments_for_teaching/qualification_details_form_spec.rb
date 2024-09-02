require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::QualificationDetailsForm do
  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:itt_academic_year) { AcademicYear.new(2023) }

  let(:journey_session) do
    create(
      :additional_payments_session,
      answers: {
        dqt_teacher_status: dqt_teacher_status,
        qualification: "postgraduate_itt",
        itt_academic_year: itt_academic_year,
        eligible_itt_subject: existing_eligible_itt_subject
      }
    )
  end

  let(:form) do
    described_class.new(
      journey: Journeys::AdditionalPaymentsForTeaching,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    let(:dqt_teacher_status) { {} }

    subject { form }

    describe "qualifications_details_check" do
      let(:existing_eligible_itt_subject) { nil }

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

  describe "#dqt_academic_date" do
    let(:params) { ActionController::Parameters.new(claim: {}) }
    let(:existing_eligible_itt_subject) { nil }

    subject { form.dqt_academic_date }

    context "when there is no academic_date" do
      let(:dqt_teacher_status) { {trn: 123456} }

      it { is_expected.to eq nil }
    end

    context "when there is an academic_date" do
      let(:dqt_teacher_status) do
        {
          initial_teacher_training: {
            programme_start_date: "2021-01-01T00:00:00"
          }
        }
      end

      it { is_expected.to eq AcademicYear.for(Date.new(2021, 1, 1)) }
    end
  end

  describe "#dqt_itt_subjects" do
    let(:params) { ActionController::Parameters.new(claim: {}) }
    let(:existing_eligible_itt_subject) { nil }

    let(:dqt_teacher_status) do
      {
        initial_teacher_training: {
          subject1: "mathematics",
          subject2: "physics",
          subject3: "chemistry"
        }
      }
    end

    subject { form.dqt_itt_subjects }

    it { is_expected.to eq("Mathematics, Physics, Chemistry") }
  end

  describe "#show_degree_subjects?" do
    let(:params) { ActionController::Parameters.new(claim: {}) }

    subject { form.show_degree_subjects? }

    context "when none of the claims have `none_of_the_above` as eligible_itt_subject" do
      let(:existing_eligible_itt_subject) { "none_of_the_above" }

      let(:itt_academic_year) { AcademicYear.new(2020) }

      let(:dqt_teacher_status) do
        {
          initial_teacher_training: {
            subject1: "mathematics"
          },
          qualifications: [
            {
              he_subject1: "mathematics"
            }
          ]
        }
      end

      it { is_expected.to be false }
    end

    context "when one of the claims has `none_of_the_above` as eligible_itt_subject" do
      let(:existing_eligible_itt_subject) { "none_of_the_above" }

      context "when there is no degree names" do
        let(:dqt_teacher_status) do
          {
            qualifications: []
          }
        end

        it { is_expected.to be false }
      end

      context "when there is a degree name" do
        let(:dqt_teacher_status) do
          {
            qualifications: [
              {
                he_subject1: "mathematics"
              }
            ]
          }
        end

        it { is_expected.to be true }
      end
    end
  end

  describe "#dqt_degree_subjects" do
    let(:params) { ActionController::Parameters.new(claim: {}) }
    let(:existing_eligible_itt_subject) { :physics }

    let(:dqt_teacher_status) do
      {
        qualifications: [
          {
            he_subject1: "chemistry",
            he_subject2: "mathematics",
            he_subject3: "physics"
          }
        ]
      }
    end

    subject { form.dqt_degree_subjects }

    it { is_expected.to eq "Chemistry, Mathematics, Physics" }
  end

  describe "#save" do
    context "when invalid" do
      let(:dqt_teacher_status) { {} }
      let(:existing_eligible_itt_subject) { "physics" }

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

        let(:journey_session) do
          create(
            :additional_payments_session,
            answers: {
              dqt_teacher_status: dqt_teacher_status,
              qualification: "postgraduate_itt",
              itt_academic_year: itt_academic_year,
              eligible_degree_subject: false,
              eligible_itt_subject: "physics"
            }
          )
        end

        it "sets the qualifications_details_check to `false`" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.qualifications_details_check
            end.from(nil).to(false)
          )
        end

        it "sets itt_academic_year as nil" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.itt_academic_year
            end.from(AcademicYear.new(2023)).to(nil)
          )
        end

        it "sets eligible_itt_subject as nil" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.eligible_itt_subject
            end.from("physics").to(nil)
          )
        end

        it "sets the qualification as nil" do
          expect { form.save }.to(
            change { journey_session.reload.answers.qualification }
            .from("postgraduate_itt").to(nil)
          )
        end

        it "sets the eligible_degree_subject as nil" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.eligible_degree_subject
            end.from(false).to(nil)
          )
        end
      end

      context "when the qualifications_details_check is `true`" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end
        let(:existing_eligible_itt_subject) { "physics" }

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
              },
              qualifications: [
                {
                  he_subject1_code: "G100"
                }
              ]
            }
          end

          let(:journey_session) do
            create(
              :additional_payments_session,
              answers: {
                dqt_teacher_status: dqt_teacher_status,
                qualification: "postgraduate_itt",
                itt_academic_year: itt_academic_year,
                eligible_degree_subject: false,
                eligible_itt_subject: "physics"
              }
            )
          end

          it "sets the qualifications_details_check to `true`" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.qualifications_details_check
              end.from(nil).to(true)
            )
          end

          it "sets the itt_academic_year to the dqt_teacher_record" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.itt_academic_year
              end.from(AcademicYear.new(2023)).to(AcademicYear.new(2018))
            )
          end

          it "sets the eligible_itt_subject to the dqt_teacher_record" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.eligible_itt_subject
              end.from("physics").to("mathematics")
            )
          end

          it "sets the qualification to the dqt_teacher_record" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.qualification
              end.from("postgraduate_itt").to("undergraduate_itt")
            )
          end

          it "sets the eligible_degree_subject to the dqt_teacher_record" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.eligible_degree_subject
              end.from(false).to(true)
            )
          end
        end

        context "when there is no dqt_teacher_record" do
          let(:dqt_teacher_status) { {} }

          it "sets the qualifications_details_check to `true`" do
            expect { form.save }.to(
              change do
                journey_session.reload.answers.qualifications_details_check
              end.from(nil).to(true)
            )
          end

          it "doesn't change the itt_academic_year" do
            expect { form.save }.not_to(
              change do
                journey_session.reload.answers.itt_academic_year
              end
            )
          end

          it "doesn't change the eligible_itt_subject" do
            expect { form.save }.not_to(
              change { journey_session.reload.answers.eligible_itt_subject }
            )
          end

          it "doesn't change the qualification" do
            expect { form.save }.not_to(
              change { journey_session.reload.answers.qualification }
            )
          end

          it "doesn't change the eligible_degree_subject" do
            expect { form.save }.not_to(
              change { journey_session.reload.answers.eligible_degree_subject }
            )
          end
        end
      end

      context "when itt_subject from DQT is outside permitted list" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end

        let(:existing_eligible_itt_subject) { nil }

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
              subject1: "geography",
              subject1_code: "ABC",
              subject2: nil,
              subject2_code: nil,
              subject3: nil,
              subject3_code: nil,
              qualification: "BA (Hons)",
              state: 0,
              state_name: "Active"
            },
            qualifications: [
              {
                he_subject1_code: "ABC"
              }
            ]
          }
        end

        it "sets eligible_itt_subject to none_of_the_above" do
          expect { form.save }.to(
            change do
              journey_session.reload.answers.eligible_itt_subject
            end.from(nil).to("none_of_the_above")
          )
        end
      end

      context "when no itt_subject from DQT" do
        let(:params) do
          ActionController::Parameters.new(
            claim: {qualifications_details_check: true}
          )
        end

        let(:existing_eligible_itt_subject) { nil }

        let(:dqt_teacher_status) { {} }

        it "makes eligible_itt_subject remain as nil" do
          expect { form.save }.not_to(
            change do
              journey_session.reload.answers.eligible_itt_subject
            end.from(nil)
          )
        end
      end
    end
  end
end
