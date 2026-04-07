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

        # With current_academic_year "2025/2026":
        # Previous financial year: Apr 6 2024 to Apr 5 2025
        context "when checking Student Loans claim school employment in previous financial year" do
          it "passes when the claimant was employed at the claim school during the previous financial year" do
            create(:journey_configuration, :student_loans, current_academic_year: "2025/2026")

            current_school = create(:school, :student_loans_eligible,
              establishment_number: 1234,
              local_authority: local_authority_camden)

            claim_school = create(:school, :student_loans_eligible,
              establishment_number: 5678,
              local_authority: local_authority_barnsley)

            claim = create(:claim, :submitted,
              policy: Policies::StudentLoans,
              submitted_at: DateTime.new(2025, 1, 12, 13, 0, 0))

            claim.eligibility.update!(
              attributes_for(:student_loans_eligibility, :eligible,
                current_school_id: current_school.id,
                teacher_reference_number: 1334426)
            )
            claim.eligibility.update!(claim_school: claim_school)

            # TPS record at current school within submission month window (Dec 2024 - Jan 2025)
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 202,
              school_urn: 1234,
              start_date: DateTime.new(2025, 1, 1, 16, 0, 0))

            # TPS record at claim school during the previous financial year
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 370,
              school_urn: 5678,
              start_date: DateTime.new(2024, 9, 1, 16, 0, 0),
              end_date: DateTime.new(2025, 2, 1, 16, 0, 0))

            described_class.new(claim: claim).perform
            task = claim.tasks.find_by(name: "employment")

            expect(task.claim_verifier_match).to eq("all")
            expect(task.passed).to eq(true)
          end

          it "does not pass when the claimant's employment at the claim school ended before the previous financial year" do
            create(:journey_configuration, :student_loans, current_academic_year: "2025/2026")

            current_school = create(:school, :student_loans_eligible,
              establishment_number: 1234,
              local_authority: local_authority_camden)

            claim_school = create(:school, :student_loans_eligible,
              establishment_number: 5678,
              local_authority: local_authority_barnsley)

            claim = create(:claim, :submitted,
              policy: Policies::StudentLoans,
              submitted_at: DateTime.new(2025, 1, 12, 13, 0, 0))

            claim.eligibility.update!(
              attributes_for(:student_loans_eligibility, :eligible,
                current_school_id: current_school.id,
                teacher_reference_number: 1334426)
            )
            claim.eligibility.update!(claim_school: claim_school)

            # TPS record at current school within submission month window (Dec 2024 - Jan 2025)
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 202,
              school_urn: 1234,
              start_date: DateTime.new(2025, 1, 1, 16, 0, 0))

            # TPS record at claim school that ENDED BEFORE the previous financial year (before Apr 6 2024)
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 370,
              school_urn: 5678,
              start_date: DateTime.new(2023, 6, 1, 16, 0, 0),
              end_date: DateTime.new(2024, 3, 1, 16, 0, 0))

            described_class.new(claim: claim).perform
            task = claim.tasks.find_by(name: "employment")

            expect(task.claim_verifier_match).to eq("none")
            expect(task.passed).to be_nil
          end

          it "does not pass when the claimant's employment at the claim school started after the previous financial year" do
            create(:journey_configuration, :student_loans, current_academic_year: "2025/2026")

            current_school = create(:school, :student_loans_eligible,
              establishment_number: 1234,
              local_authority: local_authority_camden)

            claim_school = create(:school, :student_loans_eligible,
              establishment_number: 5678,
              local_authority: local_authority_barnsley)

            claim = create(:claim, :submitted,
              policy: Policies::StudentLoans,
              submitted_at: DateTime.new(2025, 1, 12, 13, 0, 0))

            claim.eligibility.update!(
              attributes_for(:student_loans_eligibility, :eligible,
                current_school_id: current_school.id,
                teacher_reference_number: 1334426)
            )
            claim.eligibility.update!(claim_school: claim_school)

            # TPS record at current school within submission month window (Dec 2024 - Jan 2025)
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 202,
              school_urn: 1234,
              start_date: DateTime.new(2025, 1, 1, 16, 0, 0))

            # TPS record at claim school that STARTED AFTER the previous financial year (after Apr 5 2025)
            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 370,
              school_urn: 5678,
              start_date: DateTime.new(2025, 5, 1, 16, 0, 0),
              end_date: DateTime.new(2025, 8, 1, 16, 0, 0))

            described_class.new(claim: claim).perform
            task = claim.tasks.find_by(name: "employment")

            expect(task.claim_verifier_match).to eq("none")
            expect(task.passed).to be_nil
          end

          it "passes when claim school employment starts exactly on 6 April (previous FY start boundary)" do
            create(:journey_configuration, :student_loans, current_academic_year: "2025/2026")

            current_school = create(:school, :student_loans_eligible,
              establishment_number: 1234,
              local_authority: local_authority_camden)

            claim_school = create(:school, :student_loans_eligible,
              establishment_number: 5678,
              local_authority: local_authority_barnsley)

            claim = create(:claim, :submitted,
              policy: Policies::StudentLoans,
              submitted_at: DateTime.new(2025, 1, 12, 13, 0, 0))

            claim.eligibility.update!(
              attributes_for(:student_loans_eligibility, :eligible,
                current_school_id: current_school.id,
                teacher_reference_number: 1334426)
            )
            claim.eligibility.update!(claim_school: claim_school)

            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 202,
              school_urn: 1234,
              start_date: DateTime.new(2025, 1, 1, 16, 0, 0))

            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 370,
              school_urn: 5678,
              start_date: DateTime.new(2024, 4, 6, 0, 0, 0),
              end_date: DateTime.new(2024, 6, 1, 16, 0, 0))

            described_class.new(claim: claim).perform
            task = claim.tasks.find_by(name: "employment")

            expect(task.claim_verifier_match).to eq("all")
            expect(task.passed).to eq(true)
          end

          it "passes when claim school employment ends exactly on 5 April (previous FY end boundary)" do
            create(:journey_configuration, :student_loans, current_academic_year: "2025/2026")

            current_school = create(:school, :student_loans_eligible,
              establishment_number: 1234,
              local_authority: local_authority_camden)

            claim_school = create(:school, :student_loans_eligible,
              establishment_number: 5678,
              local_authority: local_authority_barnsley)

            claim = create(:claim, :submitted,
              policy: Policies::StudentLoans,
              submitted_at: DateTime.new(2025, 1, 12, 13, 0, 0))

            claim.eligibility.update!(
              attributes_for(:student_loans_eligibility, :eligible,
                current_school_id: current_school.id,
                teacher_reference_number: 1334426)
            )
            claim.eligibility.update!(claim_school: claim_school)

            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 202,
              school_urn: 1234,
              start_date: DateTime.new(2025, 1, 1, 16, 0, 0))

            create(:teachers_pensions_service,
              teacher_reference_number: 1334426,
              la_urn: 370,
              school_urn: 5678,
              start_date: DateTime.new(2025, 3, 1, 16, 0, 0),
              end_date: DateTime.new(2025, 4, 5, 0, 0, 0))

            described_class.new(claim: claim).perform
            task = claim.tasks.find_by(name: "employment")

            expect(task.claim_verifier_match).to eq("all")
            expect(task.passed).to eq(true)
          end
        end
      end
    end
  end
end
