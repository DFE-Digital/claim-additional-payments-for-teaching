require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Employment do
      subject(:employment) { described_class.new(**employment_args) }

      let!(:journey_configuration) { create(:journey_configuration, policy.to_s.underscore) }
      let!(:local_authority_barnsley) { create(:local_authority, code: "370", name: "Barnsley") }
      let!(:local_authority_camden) { create(:local_authority, code: "202", name: "Camden") }
      let!(:school) do
        create(:school,
          :early_career_payments_eligible,
          establishment_number: 8091,
          local_authority: local_authority_barnsley)
      end

      let(:claim_arg) do
        claim = create(
          :claim,
          :submitted,
          date_of_birth: Date.new(1988, 7, 18),
          first_name: "Martine",
          national_insurance_number: "RT901113D",
          reference: "QKCVAQ3K",
          surname: "Bonnet-Fontaine",
          policy: policy,
          submitted_at: DateTime.new(2022, 1, 12, 13, 0, 0)
        )

        claim.eligibility.update!(
          attributes_for(
            :"#{policy_underscored}_eligibility",
            :eligible,
            current_school_id: school.id,
            teacher_reference_number: teacher_reference_number
          )
        )

        claim
      end

      let(:employment_args) do
        {
          claim: claim_arg
        }
      end

      describe "#perform" do
        subject(:perform) { employment.perform }

        let(:policy) { Policies::TargetedRetentionIncentivePayments }

        let(:policy_underscored) { policy.to_s.underscore }
        let(:teacher_reference_number) { 1334425 }

        context "with eligible school identifier and LA code matched" do
          let!(:data_for_matching) do
            [
              create(:teachers_pensions_service, :"#{policy_underscored}_matched_first"),
              create(:teachers_pensions_service, :"#{policy_underscored}_matched_second"),
              create(:teachers_pensions_service, :"#{policy_underscored}_matched_third")
            ]
          end

          it { is_expected.to be_an_instance_of(Task) }

          describe "employment task" do
            subject(:employment_task) { claim_arg.tasks.find_by(name: "employment") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { employment_task.claim_verifier_match }

              it { is_expected.to eq "all" }
            end

            describe "#created_by" do
              subject(:created_by) { employment_task.created_by }

              it { is_expected.to eq nil }
            end

            describe "#passed" do
              subject(:passed) { employment_task.passed }

              it { is_expected.to eq true }
            end

            describe "#manual" do
              subject(:manual) { employment_task.manual }

              it { is_expected.to eq false }
            end
          end

          describe "#note" do
            subject(:note) { claim_arg.notes.last }

            before { perform }

            describe "#body" do
              subject(:body) { note.body }

              it "returns 'Eligible' with the school of employment" do
                expect(subject).to eq("[Employment] - Eligible:\n<pre>Current school: LA Code: 370 / Establishment Number: 8091\n</pre>\n")
              end
            end

            describe "#label" do
              subject(:label) { note.label }

              it { is_expected.to eq("employment") }
            end

            describe "#created_by" do
              subject(:created_by) { note.created_by }

              it { is_expected.to eq(nil) }
            end
          end

          context "when the claim is TSLR" do
            subject(:perform) { employment.perform }

            let(:teacher_reference_number) { 1334426 }
            let!(:school) do
              create(:school,
                :student_loans_eligible,
                establishment_number: 8091,
                local_authority: local_authority_camden)
            end

            let(:policy) { Policies::StudentLoans }

            before { claim_arg.eligibility.update!(claim_school: school) }

            describe "#note" do
              subject(:note) { claim_arg.notes.last }
              let!(:journey_configuration) { create(:journey_configuration, policy.to_s.underscore, current_academic_year: "2022/2023") }

              before { perform }

              describe "#body" do
                subject(:body) { note.body }

                it "returns 'Eligible' with the schools of employment" do
                  expect(body).to eq("[Employment] - Eligible:\n<pre>Current school: LA Code: 202 / Establishment Number: 8091\nClaim school: LA Code: 202 / Establishment Number: 8091\nClaim school: LA Code: 370 / Establishment Number: 4027\n</pre>\n")
                end
              end

              describe "#label" do
                subject(:label) { note.label }

                it { is_expected.to eq("employment") }
              end

              describe "#created_by" do
                subject(:created_by) { note.created_by }

                it { is_expected.to eq(nil) }
              end
            end
          end
        end

        context "with no matching Employment record" do
          let!(:data_for_matching) do
            [
              create(:teachers_pensions_service, :"#{policy_underscored}_unmatched_unmatched_jan_2022"),
              create(:teachers_pensions_service, :"#{policy_underscored}_unmatched_december_2021")
            ]
          end

          it { is_expected.to be_an_instance_of(Task) }

          describe "#employment task" do
            subject(:employment_task) { claim_arg.tasks.find_by(name: "employment") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { employment_task.claim_verifier_match }

              it { is_expected.to eq "none" }
            end

            describe "#created_by" do
              subject(:created_by) { employment_task.created_by }

              it { is_expected.to eq nil }
            end

            describe "#passed" do
              subject(:passed) { employment_task.passed }

              it { is_expected.to eq(nil) }
            end

            describe "#manual" do
              subject(:manual) { employment_task.manual }

              it { is_expected.to eq false }
            end
          end

          describe "#note" do
            subject(:note) { claim_arg.notes.last }

            before { perform }

            describe "#body" do
              subject(:body) { note.body }

              it "returns 'Ineligible' with the school details" do
                expect(subject).to eq("[Employment] - Ineligible:\n<pre>Current school: LA Code: 383 / Establishment Number: 4026\n</pre>\n")
              end
            end

            describe "#label" do
              subject(:label) { note.label }

              it { is_expected.to eq("employment") }
            end

            describe "#created_by" do
              subject(:created_by) { note.created_by }

              it { is_expected.to eq(nil) }
            end
          end
        end

        context "with no Teachers Pensions Service record" do
          it { is_expected.to be_an_instance_of(Task) }

          describe "#employment task" do
            subject(:teachers_pensions_service_task) { claim_arg.tasks.find_by(name: "employment") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { teachers_pensions_service_task.claim_verifier_match }

              it { is_expected.to be_nil }
            end

            describe "#created_by" do
              subject(:created_by) { teachers_pensions_service_task.created_by }

              it { is_expected.to eq nil }
            end

            describe "#passed" do
              subject(:passed) { teachers_pensions_service_task.passed }

              it { is_expected.to eq(nil) }
            end

            describe "#manual" do
              subject(:manual) { teachers_pensions_service_task.manual }

              it { is_expected.to eq false }
            end
          end

          describe "#note" do
            subject(:note) { claim_arg.notes.last }

            before { perform }

            describe "#body" do
              subject(:body) { note.body }

              it { is_expected.to eq("[Employment] - No data") }
            end

            describe "#label" do
              subject(:label) { note.label }

              it { is_expected.to eq("employment") }
            end

            describe "#created_by" do
              subject(:created_by) { note.created_by }

              it { is_expected.to eq(nil) }
            end
          end
        end

        context "when an employment task already exists" do
          before { create(:task, name: "employment", claim: claim_arg) }

          it "does not create duplicate tasks or notes" do
            expect { perform }.not_to change { [claim_arg.reload.notes.count, claim_arg.tasks.count] }
          end
        end
      end
    end
  end
end
