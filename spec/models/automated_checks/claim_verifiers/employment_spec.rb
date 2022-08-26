require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Employment do
      subject(:employment) { described_class.new(**employment_args) }
      let(:barnsley) { LocalAuthority.find(ActiveRecord::FixtureSet.identify(:barnsley, :uuid)) }
      let(:ecp_school) do
        create(:school,
          :early_career_payments_eligible,
          establishment_number: 8091,
          local_authority: barnsley)
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
          teacher_reference_number: teacher_reference_number,
          policy: policy,
          submitted_at: DateTime.new(2022, 1, 12, 13, 0, 0)
        )

        claim.eligibility.update!(
          attributes_for(
            :"#{policy_underscored}_eligibility",
            :eligible,
            current_school_id: ecp_school.id
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

        let(:policy) { EarlyCareerPayments }

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
                expect(subject).to eq("[Employment] - Eligible:\n<pre>School 1: LA Code: 370 / Establishment Number: 8091\n</pre>\n")
              end
            end

            describe "#created_by" do
              subject(:created_by) { note.created_by }

              it { is_expected.to eq(nil) }
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
                expect(subject).to eq("[Employment] - Ineligible:\n<pre>School 1: LA Code: 383 / Establishment Number: 4026\n</pre>\n")
              end
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
