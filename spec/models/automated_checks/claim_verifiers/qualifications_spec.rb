require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Qualifications do
      let(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: AcademicYear.new(2023)) }

      let(:dqt_higher_education_qualifications) { [] }

      before do
        dqt_higher_education_qualifications

        if data
          body = data

          status = 200
        else
          body = {}

          status = 404
        end

        stub_qualified_teaching_statuses_show(
          trn: claim_arg.eligibility.teacher_reference_number,
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
        travel_to Date.new(2024, 3, 1) do
          claim = create(
            :claim,
            :submitted,
            date_of_birth: Date.new(1990, 8, 23),
            first_name: "Fred",
            national_insurance_number: "AB100000C",
            reference: "AB123456",
            surname: "ELIGIBLE",
            policy: Policies::TargetedRetentionIncentivePayments
          )

          claim.eligibility.update!(
            attributes_for(
              :targeted_retention_incentive_payments_eligibility,
              :eligible,
              qualification: :undergraduate_itt,
              teacher_reference_number: "1234567",
              itt_academic_year: Policies::TargetedRetentionIncentivePayments.current_academic_year - 3
            )
          )

          claim
        end
      end

      let(:qualifications_args) do
        {
          claim: claim_arg,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim_arg.eligibility.teacher_reference_number,
            include: "alerts,induction,routesToProfessionalStatuses"
          )
        }
      end

      describe "#perform" do
        subject(:perform) do
          travel_to Date.new(2024, 3, 1) do
            qualifications.perform
          end
        end

        context "with eligible qualifications" do
          let(:data) do
            {
              qts: {
                holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 2).to_s
              },
              routesToProfessionalStatuses: [
                {
                  holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 2).to_s,
                  trainingSubjects: [
                    {
                      name: "mathematics",
                      reference: "G100"
                    }
                  ],
                  trainingStartDate: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 1).to_s,
                  trainingEndDate: nil,
                  routeToProfessionalStatusType: {
                    name: "Primary and secondary undergraduate fee funded"
                  }
                }
              ]
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
                  qts: {
                    holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year - 1, 9, 2).to_s
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
                        ITT subject codes:  ["G100"]
                        Degree codes:       []
                        ITT start date:     2020-09-01
                        QTS award date:     2019-09-02
                        Qualification name: Primary and secondary undergraduate fee funded
                      </pre>
                    HTML
                  )
                end

                context "with qualifications" do
                  let(:dqt_higher_education_qualification1) do
                    create(
                      :dqt_higher_education_qualification,
                      teacher_reference_number: claim_arg.eligibility.teacher_reference_number,
                      date_of_birth: claim_arg.date_of_birth,
                      subject_code: "100403"
                    )
                  end

                  let(:dqt_higher_education_qualification2) do
                    create(
                      :dqt_higher_education_qualification,
                      teacher_reference_number: claim_arg.eligibility.teacher_reference_number,
                      date_of_birth: claim_arg.date_of_birth,
                      subject_code: "100105"
                    )
                  end

                  let(:dqt_higher_education_qualifications) do
                    [dqt_higher_education_qualification1, dqt_higher_education_qualification2]
                  end

                  it do
                    is_expected.to eq(
                      <<~HTML
                        [DQT Qualification] - Ineligible:
                        <pre>
                          ITT subjects: ["mathematics"]
                          ITT subject codes:  ["G100"]
                          Degree codes:       ["100403", "100105"]
                          ITT start date:     2020-09-01
                          QTS award date:     2019-09-02
                          Qualification name: Primary and secondary undergraduate fee funded
                        </pre>
                      HTML
                    )
                  end
                end
              end

              describe "#label" do
                subject(:label) { note.label }

                it { is_expected.to eq("qualifications") }
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
                  routesToProfessionalStatuses: [
                    {
                      holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 2).to_s,
                      trainingSubjects: [
                        {
                          name: nil,
                          reference: "NoCode"
                        }
                      ],
                      trainingStartDate: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 1).to_s,
                      trainingEndDate: nil,
                      routeToProfessionalStatusType: {
                        name: "Primary and secondary undergraduate fee funded"
                      }
                    }
                  ]
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
                        ITT start date:     2020-09-01
                        QTS award date:     2020-09-02
                        Qualification name: Primary and secondary undergraduate fee funded
                      </pre>
                    HTML
                  )
                end
              end

              describe "#label" do
                subject(:label) { note.label }

                it { is_expected.to eq("qualifications") }
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
                policy: Policies::TargetedRetentionIncentivePayments,
                date_of_birth: Date.new(1990, 8, 23),
                first_name: "Fred",
                national_insurance_number: "AB100000C",
                reference: "AB123456",
                surname: "ELIGIBLE",
                tasks: [build(:task, name: :qualifications)],
                eligibility_attributes: {teacher_reference_number: "1234567"}
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
              {
                qts: {
                  holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year - 1, 9, 2).to_s
                },
                routesToProfessionalStatuses: [
                  {
                    holdsFrom: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 2).to_s,
                    trainingSubjects: [
                      {
                        name: nil,
                        reference: "NoCode"
                      }
                    ],
                    trainingStartDate: Date.new(claim_arg.eligibility.itt_academic_year.start_year, 9, 1).to_s,
                    trainingEndDate: nil,
                    routeToProfessionalStatusType: {
                      name: "Primary and secondary undergraduate fee funded"
                    }
                  }
                ]
              }
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
                        ITT start date:     2020-09-01
                        QTS award date:     2019-09-02
                        Qualification name: Primary and secondary undergraduate fee funded
                      </pre>
                    HTML
                  )
                end
              end

              describe "#label" do
                subject(:label) { note.label }

                it { is_expected.to eq("qualifications") }
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

            describe "#label" do
              subject(:label) { note.label }

              it { is_expected.to eq("qualifications") }
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
