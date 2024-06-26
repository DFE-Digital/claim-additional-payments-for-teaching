require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe CensusSubjectsTaught do
      subject(:census_subjects_taught) { described_class.new(**census_subjects_taught_args) }

      let(:claim_arg) do
        claim = create(
          :claim,
          :submitted,
          date_of_birth: Date.new(1988, 7, 18),
          first_name: "Martine",
          national_insurance_number: "RT901113D",
          reference: "QKCVAQ3K",
          surname: "Bonnet-Fontaine",
          policy: policy
        )

        if policy == Policies::EarlyCareerPayments
          claim.eligibility.update!(
            attributes_for(
              :"#{policy_underscored}_eligibility",
              :eligible,
              eligible_itt_subject: :mathematics,
              teacher_reference_number: teacher_reference_number
            )
          )
        elsif policy == Policies::LevellingUpPremiumPayments
          claim.eligibility.update!(
            attributes_for(
              :"#{policy_underscored}_eligibility",
              :eligible,
              eligible_itt_subject: :computing,
              teacher_reference_number: teacher_reference_number
            )
          )
        elsif policy == Policies::StudentLoans
          claim.eligibility.update!(
            attributes_for(
              :"#{policy_underscored}_eligibility",
              :eligible,
              biology_taught: true,
              computing_taught: true,
              physics_taught: false,
              teacher_reference_number: teacher_reference_number
            )
          )
        end

        claim
      end

      let(:census_subjects_taught_args) do
        {
          claim: claim_arg
        }
      end

      describe "#perform" do
        subject(:perform) { census_subjects_taught.perform }

        [
          Policies::EarlyCareerPayments,
          Policies::StudentLoans,
          Policies::LevellingUpPremiumPayments
        ].each do |policy|
          context "with policy #{policy}" do
            let(:policy) { policy }
            let(:policy_underscored) { policy.to_s.underscore }
            let(:teacher_reference_number) do
              case policy
              when Policies::EarlyCareerPayments
                9855512
              when Policies::LevellingUpPremiumPayments
                1560179
              when Policies::StudentLoans
                2109438
              end
            end

            context "eligible_itt_subject is none_of_the_above" do
              let!(:matched) { create(:school_workforce_census, :"#{policy_underscored}_matched") }

              let(:claim_arg) do
                claim = create(
                  :claim,
                  :submitted,
                  date_of_birth: Date.new(1988, 7, 18),
                  first_name: "Martine",
                  national_insurance_number: "RT901113D",
                  reference: "QKCVAQ3K",
                  surname: "Bonnet-Fontaine",
                  policy: policy
                )

                if policy == Policies::EarlyCareerPayments
                  claim.eligibility.update!(
                    attributes_for(
                      :"#{policy_underscored}_eligibility",
                      :eligible,
                      eligible_itt_subject: :none_of_the_above,
                      teacher_reference_number: teacher_reference_number
                    )
                  )
                elsif policy == Policies::LevellingUpPremiumPayments
                  claim.eligibility.update!(
                    attributes_for(
                      :"#{policy_underscored}_eligibility",
                      :eligible,
                      eligible_itt_subject: :none_of_the_above,
                      teacher_reference_number: teacher_reference_number
                    )
                  )
                elsif policy == Policies::StudentLoans
                  claim.eligibility.update!(
                    attributes_for(
                      :"#{policy_underscored}_eligibility",
                      :eligible,
                      biology_taught: false,
                      computing_taught: false,
                      physics_taught: false,
                      teacher_reference_number: teacher_reference_number
                    )
                  )
                end

                claim
              end

              subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

              before { perform }

              describe "#claim_verifier_match" do
                subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

                it { is_expected.to eq "none" }
              end
            end

            context "with any eligible subject matched" do
              let!(:matched) { create(:school_workforce_census, :"#{policy_underscored}_matched") }
              let!(:matched1) { create(:school_workforce_census, :"#{policy_underscored}_matched") }

              it { is_expected.to be_an_instance_of(Task) }

              describe "census_subjects_taught task" do
                subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

                  it { is_expected.to eq "any" }
                end

                describe "#created_by" do
                  subject(:created_by) { census_subjects_taught_task.created_by }

                  it { is_expected.to eq nil }
                end

                describe "#passed" do
                  subject(:passed) { census_subjects_taught_task.passed }

                  it { is_expected.to eq true }
                end

                describe "#manual" do
                  subject(:manual) { census_subjects_taught_task.manual }

                  it { is_expected.to eq false }
                end
              end

              describe "#note" do
                subject(:note) { claim_arg.notes.last }

                before { perform }

                describe "#body" do
                  subject(:body) { note.body }

                  it "returns 'Eligible' with the school workforce census subjects", if: policy == Policies::EarlyCareerPayments do
                    expect(subject).to eq("[School Workforce Census] - Eligible:\n<pre>Subject 1: Mathematics\nSubject 2: Mathematics\n</pre>\n")
                  end

                  it "returns 'Eligible' with the school workforce census subjects", if: policy == Policies::LevellingUpPremiumPayments do
                    expect(subject).to eq("[School Workforce Census] - Eligible:\n<pre>Subject 1: ICT\nSubject 2: ICT\n</pre>\n")
                  end

                  it "returns 'Eligible' with the school workforce census subjects", if: policy == Policies::StudentLoans do
                    expect(subject).to eq("[School Workforce Census] - Eligible:\n<pre>Subject 1: Biology\nSubject 2: Biology\n</pre>\n")
                  end
                end

                describe "#label" do
                  subject(:label) { note.label }

                  it { is_expected.to eq("census_subjects_taught") }
                end

                describe "#created_by" do
                  subject(:created_by) { note.created_by }

                  it { is_expected.to eq(nil) }
                end
              end
            end

            context "with no matching School Workforce Census record" do
              let!(:unmatched) { create(:school_workforce_census, :"#{policy_underscored}_unmatched") }

              it { is_expected.to be_an_instance_of(Task) }

              describe "#census_subjects_taught task" do
                subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

                  it { is_expected.to eq "none" }
                end

                describe "#created_by" do
                  subject(:created_by) { census_subjects_taught_task.created_by }

                  it { is_expected.to eq nil }
                end

                describe "#passed" do
                  subject(:passed) { census_subjects_taught_task.passed }

                  it { is_expected.to eq(nil) }
                end

                describe "#manual" do
                  subject(:manual) { census_subjects_taught_task.manual }

                  it { is_expected.to eq false }
                end
              end

              describe "#note" do
                subject(:note) { claim_arg.notes.last }

                before { perform }

                describe "#body" do
                  subject(:body) { note.body }

                  it "returns 'Ineligible' with the school workforce census subjects", if: policy == Policies::EarlyCareerPayments do
                    expect(subject).to eq("[School Workforce Census] - Ineligible:\n<pre>Subject 1: Problem Solving, Reasoning and Numeracy\n</pre>\n")
                  end

                  it "returns 'Ineligible' with the school workforce census subjects", if: policy == Policies::LevellingUpPremiumPayments do
                    expect(subject).to eq("[School Workforce Census] - Ineligible:\n<pre>Subject 1: Problem Solving, Reasoning and Numeracy\n</pre>\n")
                  end

                  it "returns 'Ineligible' with the school workforce census subjects", if: policy == Policies::StudentLoans do
                    expect(subject).to eq("[School Workforce Census] - Ineligible:\n<pre>Subject 1: Other Mathematical Subject\n</pre>\n")
                  end
                end

                describe "#label" do
                  subject(:label) { note.label }

                  it { is_expected.to eq("census_subjects_taught") }
                end

                describe "#created_by" do
                  subject(:created_by) { note.created_by }

                  it { is_expected.to eq(nil) }
                end
              end
            end

            context "with no School Workforce Census record" do
              it { is_expected.to be_an_instance_of(Task) }

              describe "#census_subjects_taught task" do
                subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

                  it { is_expected.to be_nil }
                end

                describe "#created_by" do
                  subject(:created_by) { census_subjects_taught_task.created_by }

                  it { is_expected.to eq nil }
                end

                describe "#passed" do
                  subject(:passed) { census_subjects_taught_task.passed }

                  it { is_expected.to eq(nil) }
                end

                describe "#manual" do
                  subject(:manual) { census_subjects_taught_task.manual }

                  it { is_expected.to eq false }
                end
              end

              describe "#note" do
                subject(:note) { claim_arg.notes.last }

                before { perform }

                describe "#body" do
                  subject(:body) { note.body }

                  it { is_expected.to eq("[School Workforce Census] - No data") }
                end

                describe "#label" do
                  subject(:label) { note.label }

                  it { is_expected.to eq("census_subjects_taught") }
                end

                describe "#created_by" do
                  subject(:created_by) { note.created_by }

                  it { is_expected.to eq(nil) }
                end
              end
            end

            context "when admin claims tasks census_subjects_taught passed" do
              let(:claim_arg) do
                create(
                  :claim,
                  :submitted,
                  date_of_birth: Date.new(1988, 7, 18),
                  first_name: "Martine",
                  national_insurance_number: "RT901113D",
                  reference: "QKCVAQ3K",
                  surname: "Bonnet-Fontaine",
                  policy: policy,
                  tasks: [build(:task, name: :census_subjects_taught)],
                  eligibility_attributes: {teacher_reference_number: teacher_reference_number}
                )
              end

              it { is_expected.to eq(nil) }

              describe "census_subjects_taught task" do
                subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

                before { perform }

                describe "#claim_verifier_match" do
                  subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

                  it { is_expected.to eq(nil) }
                end

                describe "#created_by" do
                  subject(:created_by) { census_subjects_taught_task.created_by }

                  it { is_expected.to be_an_instance_of(DfeSignIn::User) }
                end

                describe "#passed" do
                  subject(:passed) { census_subjects_taught_task.passed }

                  it { is_expected.to eq true }
                end

                describe "#manual" do
                  subject(:manual) { census_subjects_taught_task.manual }

                  it { is_expected.to eq true }
                end
              end

              describe "note" do
                subject(:note) { claim_arg.notes.last }

                before { perform }

                it { is_expected.to eq(nil) }
              end
            end
          end
        end

        context "TSLR - languages_taught is mapped to foreign_languages" do
          let(:teacher_reference_number) { 3403431 }

          let(:claim_arg) do
            claim = create(
              :claim,
              :submitted,
              date_of_birth: Date.new(1988, 7, 18),
              first_name: "Martine",
              national_insurance_number: "RT901113D",
              reference: "QKCVAQ3K",
              surname: "Bonnet-Fontaine",
              policy: Policies::StudentLoans
            )

            claim.eligibility.update!(
              attributes_for(
                :student_loans_eligibility,
                :eligible,
                biology_taught: false,
                computing_taught: false,
                physics_taught: false,
                languages_taught: true,
                teacher_reference_number: teacher_reference_number
              )
            )

            claim
          end

          context "with any eligible subject matched" do
            let!(:matched) { create(:school_workforce_census, :student_loans_matched_languages_only) }

            subject(:census_subjects_taught_task) { claim_arg.tasks.find_by(name: "census_subjects_taught") }

            before { perform }

            describe "#claim_verifier_match" do
              subject(:claim_verifier_match) { census_subjects_taught_task.claim_verifier_match }

              it { is_expected.to eq "any" }
            end
          end
        end
      end
    end
  end
end
