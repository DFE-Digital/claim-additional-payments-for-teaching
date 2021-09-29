require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Qualifications do
      before do
        if data
          body = {
            data: [data]
          }

          status = 200
        else
          body = {
            data: nil,
            message: "No records found."
          }

          status = 404
        end

        stub_qualified_teaching_statuses_show(
          query: {
            trn: claim_arg.teacher_reference_number,
            ni: claim_arg.national_insurance_number
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
          dqt_teacher_statuses: Dqt::Client.new.api.qualified_teaching_statuses.show(
            params: {
              teacher_reference_number: claim_arg.teacher_reference_number,
              national_insurance_number: claim_arg.national_insurance_number
            }
          )
        }
      end

      describe "#perform" do
        subject(:perform) { qualifications.perform }

        context "with eligible qualifications" do
          let(:data) do
            {
              ittStartDate: Date.new(2015, 9, 1),
              ittSubject1Code: MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first,
              qualificationName: "BA",
              qtsAwardDate: Date.new(
                MathsAndPhysics.first_eligible_qts_award_year.start_year,
                9,
                1
              )
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
                  qtsAwardDate: Date.new(
                    MathsAndPhysics.first_eligible_qts_award_year.start_year - 1,
                    9,
                    1
                  )
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
                      Ineligible:
                      <pre>
                        ITT subject codes:  ["100400"]
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

          context "without eligible ITT subjects codes" do
            let(:data) do
              super().merge(
                {
                  ittSubject1Code: "NoCode"
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
                      Ineligible:
                      <pre>
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
                  ittSubject1Code: "NoCode",
                  qtsAwardDate: Date.new(
                    MathsAndPhysics.first_eligible_qts_award_year.start_year - 1,
                    9,
                    1
                  )
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
                      Ineligible:
                      <pre>
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

              it { is_expected.to eq("Not eligible") }
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
