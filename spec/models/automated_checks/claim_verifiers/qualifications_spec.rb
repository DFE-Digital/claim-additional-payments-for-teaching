require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Qualifications do
      before do
        if data.nil?
          body = <<~JSON
            {
              "data": null,
              "message": "No records found."
            }
          JSON

          status = 404
        else
          body = <<~JSON
            {
              "data": [
                {
                  "trn": "#{data[:teacher_reference_number]}",
                  "name": "#{data[:name]}",
                  "doB": "#{data[:date_of_birth] || Date.today}",
                  "niNumber": "#{data[:national_insurance_number]}",
                  "qtsAwardDate": "#{data[:qts_award_date] || Date.today}",
                  "ittSubject1Code": "#{data.dig(:itt_subject_codes, 0)}",
                  "ittSubject2Code": "#{data.dig(:itt_subject_codes, 1)}",
                  "ittSubject3Code": "#{data.dig(:itt_subject_codes, 2)}",
                  "activeAlert": true,
                  "qualificationName": "#{data[:qualification_name] || "BA"}",
                  "ittStartDate": "#{data[:itt_start_date] || Date.today}"
                }
              ],
              "message": null
            }
          JSON

          status = 200
        end

        stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status").with(
          query: WebMock::API.hash_including(
            {
              trn: claim.teacher_reference_number,
              niNumber: claim.national_insurance_number
            }
          )
        ).to_return(body: body, status: status)
      end

      subject(:qualifications) { described_class.new(**qualifications_args) }

      let(:claim) do
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
          claim: claim,
          dqt_teacher_status: Dqt::Client.new.api.qualified_teaching_status.show(
            params: {
              teacher_reference_number: claim.teacher_reference_number,
              national_insurance_number: claim.national_insurance_number
            }
          )
        }
      end

      describe "#perform" do
        subject(:perform) { qualifications.perform }

        context "with eligible qualifications" do
          let(:data) do
            {
              qts_award_date: Date.new(
                MathsAndPhysics.first_eligible_qts_award_year.start_year,
                9,
                1
              ),
              itt_subject_codes: [MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first]
            }
          end

          it { is_expected.to be_an_instance_of(Task) }

          describe "qualifications task" do
            subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
            subject(:note) { claim.notes.last }

            it { is_expected.to eq(nil) }
          end

          context "except QTS award date" do
            let(:data) do
              {
                qts_award_date: Date.new(
                  MathsAndPhysics.first_eligible_qts_award_year.start_year - 1.year,
                  9,
                  1
                ),
                itt_subject_codes: [MathsAndPhysics::DqtRecord::ELIGIBLE_MATHS_HECOS_CODES.first]
              }
            end

            it { is_expected.to be_an_instance_of(Task) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
              subject(:note) { claim.notes.last }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it do
                  is_expected.to eq(
                    <<~HTML
                      Ineligible:
                      <pre>
                        ITT subject codes: ["100400", "", ""]
                        Degree codes:      []
                        QTS award date:    -31554937-09-01T00:00:00+00:00
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

          context "except ITT subjects codes" do
            let(:data) do
              {
                qts_award_date: Date.new(
                  MathsAndPhysics.first_eligible_qts_award_year.start_year,
                  9,
                  1
                ),
                itt_subject_codes: ["NoCode"]
              }
            end

            it { is_expected.to be_an_instance_of(Task) }

            describe "qualifications task" do
              subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
              subject(:note) { claim.notes.last }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it do
                  is_expected.to eq(
                    <<~HTML
                      Ineligible:
                      <pre>
                        ITT subject codes: ["NoCode", "", ""]
                        Degree codes:      []
                        QTS award date:    2015-09-01T00:00:00+00:00
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
            let(:claim) do
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
              subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
              subject(:note) { claim.notes.last }

              before { perform }

              it { is_expected.to eq(nil) }
            end
          end
        end

        context "without eligible qualifications" do
          let(:data) do
            {
              qts_award_date: Date.new(
                MathsAndPhysics.first_eligible_qts_award_year.start_year - 1.year,
                9,
                1
              ),
              itt_subject_codes: ["NoCode"]
            }
          end

          it { is_expected.to be_an_instance_of(Task) }

          describe "qualifications task" do
            subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
            subject(:note) { claim.notes.last }

            before { perform }

            describe "#body" do
              subject(:body) { note.body }

              it do
                is_expected.to eq(
                  <<~HTML
                    Ineligible:
                    <pre>
                      ITT subject codes: ["NoCode", "", ""]
                      Degree codes:      []
                      QTS award date:    -31554937-09-01T00:00:00+00:00
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

        context "without matching DQT record" do
          let(:data) { nil }

          it { is_expected.to be_an_instance_of(Task) }

          describe "qualifications task" do
            subject(:qualifications_task) { claim.tasks.find_by(name: "qualifications") }

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
            subject(:note) { claim.notes.last }

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
