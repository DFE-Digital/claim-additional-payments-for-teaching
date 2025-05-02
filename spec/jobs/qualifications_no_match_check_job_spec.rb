require "rails_helper"

RSpec.describe QualificationsNoMatchCheckJob do
  before do
    stub_qualified_teaching_statuses_show(
      trn: claim.eligibility.teacher_reference_number,
      params: {
        birthdate: claim.date_of_birth&.to_s,
        nino: claim.national_insurance_number
      }
    )

    create(:task, claim: claim, name: "qualifications", claim_verifier_match: claim_verifier_match, manual: false)
  end

  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments_only) }
  let(:academic_year) { journey_configuration.current_academic_year }

  let(:claim) do
    create(
      :claim,
      :submitted,
      academic_year: academic_year,
      policy: Policies::TargetedRetentionIncentivePayments
    )
  end

  let(:claim_verifier_match) { nil }

  describe "#perform" do
    context "when qualification task did not run" do
      before do
        claim.tasks.delete_all
      end

      it "does not re-run the task" do
        expect { described_class.new.perform }
          .to(not_change { claim.notes.count })

        expect(Task.count).to eq(0)
      end
    end

    context "when qualifications check returned no data" do
      it "does not re-run the task" do
        expect { described_class.new.perform }
          .to not_change { claim.notes.count }
          .and(not_change { claim.tasks.last.created_at })
      end
    end

    context "when qualifications check returned no match" do
      let(:claim_verifier_match) { :none }

      it "re-runs the task" do
        expect { described_class.new.perform }
          .to change { claim.notes.count }.by(1)
          .and(change { claim.tasks.last.created_at })
      end

      context "when passing a qts_award_for_non_pg scope" do
        before do
          described_class.new.perform
        end

        it "re-runs the task without updates" do
          expect { described_class.new.perform(filter: :qts_award_for_non_pg) }
            .to not_change { claim.notes.count }
            .and(not_change { claim.tasks.last.created_at })
        end

        context "when the conditions of the filter are being met" do
          before do
            note_body =
              <<~HTML
                Ineligible:
                <pre>
                  ITT subjects: ["Theology and the Universe", "", ""]
                  ITT subject codes:  ["TT100", "", ""]
                  Degree codes:       []
                  ITT start date:     2015-09-01
                  QTS award date:     2016-09-01
                  Qualification name: QTS Award
                </pre>
              HTML

            claim.notes = [build(:note, body: note_body, label: "qualifications")]
            claim.eligibility.qualification = :undergraduate_itt
            claim.save
          end

          it "re-runs the task with updates" do
            expect { described_class.new.perform(filter: :qts_award_for_non_pg) }
              .to change { claim.notes.count }.by(1)
              .and(change { claim.tasks.last.created_at })
          end
        end
      end
    end

    context "when qualifications check returned passed" do
      let(:claim_verifier_match) { :all }

      it "does not re-run the task" do
        expect { described_class.new.perform }
          .to not_change { claim.notes.count }
          .and(not_change { claim.tasks.last.created_at })
      end
    end
  end
end
