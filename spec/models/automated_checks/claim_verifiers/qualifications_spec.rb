require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Qualifications do
      before do
        if data
          body = data

          status = 200
        else
          body = {}

          status = 404
        end

        stub_qualified_teaching_statuses_show(
          trn: claim_arg.teacher_reference_number,
          params: {
            birthdate: claim_arg.date_of_birth&.to_s,
            nino: claim_arg.national_insurance_number
          },
          body: body,
          status: status
        )
      end

      subject(:qualifications) { described_class.new(**qualifications_args) }

      let(:claim_arg) do
        claim = create(
          :claim,
          :submitted,
          date_of_birth: Date.new(1990, 8, 23),
          first_name: "Fred",
          national_insurance_number: "QQ100000C",
          reference: "AB123456",
          surname: "ELIGIBLE",
          teacher_reference_number: "1234567",
          policy: MathsAndPhysics
        )

        claim.eligibility.update!(
          attributes_for(
            :maths_and_physics_eligibility,
            :eligible,
            initial_teacher_training_subject: :maths
          )
        )

        claim
      end

      let(:qualifications_args) do
        {
          claim: claim_arg,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim_arg.teacher_reference_number,
            birthdate: claim_arg.date_of_birth,
            nino: claim_arg.national_insurance_number
          )
        }
      end

      describe "#perform" do
        subject(:perform) { qualifications.perform }

        context "with eligible qualifications" do
          let(:data) do
            {
              initial_teacher_training: {
                programme_start_date: Date.new(2015, 9, 1),
                subject1: "mathematics",
                subject1_code: MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first,
                qualification: "BA"
              },
              qualified_teacher_status: {
                qts_date: Date.new(
                  MathsAndPhysics.first_eligible_qts_award_year.start_year,
                  9,
                  1
                )
              }
            }
          end

          it { is_expected.to be_an_instance_of(Task) }

          describe "qualifications task" do
            subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

              it { is_expected.to eq "all" }
            end

            describe "#created_by" do
              subject(:created_by) { qualifications_task.created_by }

              it { is_expected.to eq nil }
            end

            describe "#passed" do
              subject(:passed) { qualifications_task.passed }

              it { is_expected.to eq true }
            end

            describe "#manual" do
              subject(:manual) { qualifications_task.manual }

              it { is_expected.to eq false }
            end
          end

          describe "note" do
            subject(:note) { claim_arg.notes.last }

            it { is_expected.to eq(nil) }
          end

          context "without eligible QTS award date" do
            let(:data) do
              super().merge(
                {
                  qualified_teacher_status: {
                    qts_date: Date.new(
                      MathsAndPhysics.first_eligible_qts_award_year.start_year - 1,
                      9,
                      1
                    )
                  }
                }
              )
            end

            it { is_expected.to be_an_instance_of(Task) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

              before { perform }

              describe "#claim_verifier_match" do
                subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

                it { is_expected.to eq "none" }
              end

              describe "#created_by" do
                subject(:created_by) { qualifications_task.created_by }

                it { is_expected.to eq nil }
              end

              describe "#passed" do
                subject(:passed) { qualifications_task.passed }

                it { is_expected.to eq nil }
              end

              describe "#manual" do
                subject(:manual) { qualifications_task.manual }

                it { is_expected.to eq false }
              end
            end

            describe "note" do
              subject(:note) { claim_arg.notes.last }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it do
                  is_expected.to eq(
                    <<~HTML
                      [DQT Qualification] - Ineligible:
                      <pre>
                        ITT subjects: ["mathematics"]
                        ITT subject codes:  ["100400"]
                        Degree codes:       []
                        ITT start date:     2015-09-01
                        QTS award date:     2014-09-01
                        Qualification name: BA
                      </pre>
                    HTML
                  )
                end

                context "with qualifications" do
                  let(:data) do
                    super().merge(
                      {
                        qualifications: [
                          {
                            he_subject1_code: "100403",
                            he_subject2_code: "100105",
                            he_subject3_code: nil
                          }
                        ]
                      }
                    )
                  end

                  it do
                    is_expected.to eq(
                      <<~HTML
                        [DQT Qualification] - Ineligible:
                        <pre>
                          ITT subjects: ["mathematics"]
                          ITT subject codes:  ["100400"]
                          Degree codes:       ["100403", "100105"]
                          ITT start date:     2015-09-01
                          QTS award date:     2014-09-01
                          Qualification name: BA
                        </pre>
                      HTML
                    )
                  end
                end
              end

              describe "#created_by" do
                subject(:created_by) { note.created_by }

                it { is_expected.to eq(nil) }
              end
            end
          end

          context "without eligible ITT subjects codes" do
            let(:data) do
              super().merge(
                {
                  initial_teacher_training: {
                    subject1: nil,
                    subject1_code: "NoCode",
                    programme_start_date: super().dig(:initial_teacher_training, :programme_start_date),
                    qualification: super().dig(:initial_teacher_training, :qualification)
                  }
                }
              )
            end

            it { is_expected.to be_an_instance_of(Task) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

              before { perform }

              describe "#claim_verifier_match" do
                subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

                it { is_expected.to eq "none" }
              end

              describe "#created_by" do
                subject(:created_by) { qualifications_task.created_by }

                it { is_expected.to eq nil }
              end

              describe "#passed" do
                subject(:passed) { qualifications_task.passed }

                it { is_expected.to eq nil }
              end

              describe "#manual" do
                subject(:manual) { qualifications_task.manual }

                it { is_expected.to eq false }
              end
            end

            describe "note" do
              subject(:note) { claim_arg.notes.last }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it do
                  is_expected.to eq(
                    <<~HTML
                      [DQT Qualification] - Ineligible:
                      <pre>
                        ITT subjects: []
                        ITT subject codes:  ["NoCode"]
                        Degree codes:       []
                        ITT start date:     2015-09-01
                        QTS award date:     2015-09-01
                        Qualification name: BA
                      </pre>
                    HTML
                  )
                end
              end

              describe "#created_by" do
                subject(:created_by) { note.created_by }

                it { is_expected.to eq(nil) }
              end
            end
          end

          context "with admin claims tasks qualifications passed" do
            let(:claim_arg) do
              create(
                :claim,
                :submitted,
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "QQ100000C",
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: :qualifications)],
                teacher_reference_number: "1234567"
              )
            end

            it { is_expected.to eq(nil) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

              before { perform }

              describe "#claim_verifier_match" do
                subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

                it { is_expected.to eq nil }
              end

              describe "#created_by" do
                subject(:created_by) { qualifications_task.created_by }

                it { is_expected.to be_an_instance_of(DfeSignIn::User) }
              end

              describe "#passed" do
                subject(:passed) { qualifications_task.passed }

                it { is_expected.to eq true }
              end

              describe "#manual" do
                subject(:manual) { qualifications_task.manual }

                it { is_expected.to eq true }
              end
            end

            describe "note" do
              subject(:note) { claim_arg.notes.last }

              before { perform }

              it { is_expected.to eq(nil) }
            end
          end

          context "without multiple eligibilities" do
            let(:data) do
              super().merge(
                {
                  initial_teacher_training: {
                    subject1: nil,
                    subject1_code: "NoCode",
                    qualification: super().dig(:initial_teacher_training, :qualification),
                    programme_start_date: super().dig(:initial_teacher_training, :programme_start_date)
                  },
                  qualified_teacher_status: {
                    qts_date: Date.new(
                      MathsAndPhysics.first_eligible_qts_award_year.start_year - 1,
                      9,
                      1
                    )
                  }
                }
              )
            end

            it { is_expected.to be_an_instance_of(Task) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

              before { perform }

              describe "#claim_verifier_match" do
                subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

                it { is_expected.to eq "none" }
              end

              describe "#created_by" do
                subject(:created_by) { qualifications_task.created_by }

                it { is_expected.to eq nil }
              end

              describe "#passed" do
                subject(:passed) { qualifications_task.passed }

                it { is_expected.to eq nil }
              end

              describe "#manual" do
                subject(:manual) { qualifications_task.manual }

                it { is_expected.to eq false }
              end
            end

            describe "note" do
              subject(:note) { claim_arg.notes.last }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it do
                  is_expected.to eq(
                    <<~HTML
                      [DQT Qualification] - Ineligible:
                      <pre>
                        ITT subjects: []
                        ITT subject codes:  ["NoCode"]
                        Degree codes:       []
                        ITT start date:     2015-09-01
                        QTS award date:     2014-09-01
                        Qualification name: BA
                      </pre>
                    HTML
                  )
                end
              end

              describe "#created_by" do
                subject(:created_by) { note.created_by }

                it { is_expected.to eq(nil) }
              end
            end
          end
        end

        context "without matching DQT record" do
          let(:data) { nil }

          it { is_expected.to be_an_instance_of(Task) }

          describe "qualifications task" do
            subject(:qualifications_task) { claim_arg.tasks.find_by(name: "qualifications") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { qualifications_task.claim_verifier_match }

              it { is_expected.to eq "none" }
            end

            describe "#created_by" do
              subject(:created_by) { qualifications_task.created_by }

              it { is_expected.to eq nil }
            end

            describe "#passed" do
              subject(:passed) { qualifications_task.passed }

              it { is_expected.to eq nil }
            end

            describe "#manual" do
              subject(:manual) { qualifications_task.manual }

              it { is_expected.to eq false }
            end
          end

          describe "note" do
            subject(:note) { claim_arg.notes.last }

            before { perform }

            describe "#body" do
              subject(:body) { note.body }

              it { is_expected.to eq("[DQT Qualification] - Not eligible") }
            end

            describe "#created_by" do
              subject(:created_by) { note.created_by }

              it { is_expected.to eq(nil) }
            end
          end
        end
      end
    end
  end
end
