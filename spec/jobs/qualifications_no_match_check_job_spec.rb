require "rails_helper"

RSpec.describe QualificationsNoMatchCheckJob do
  before do
    stub_qualified_teaching_statuses_show(
      trn: claim.teacher_reference_number,
      params: {
        birthdate: claim.date_of_birth&.to_s,
        nino: claim.national_insurance_number
      }
    )

    create(:task, claim: claim, name: "qualifications", claim_verifier_match: claim_verifier_match, manual: false)
  end

  let(:claim) { create(:claim, :submitted, academic_year: PolicyConfiguration.for(EarlyCareerPayments).current_academic_year) }
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
