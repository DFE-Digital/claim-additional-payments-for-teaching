require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::TeacherAuthIdentityConfirmation do
  describe "#perform" do
    context "when national_insurance_number doesn't match" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::StudentLoans,
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            teacher_auth_national_insurance_number: "AA111111C"
          },
          dqt_teacher_status: {
            qts: {
              holdsFrom: "2014-01-01"
            }
          }
        )
      end

      before { described_class.new(claim: claim).perform }

      it "adds a note to the claim" do
        expect(
          claim.notes.by_label("teacher_auth_identity_confirmation").where(
            "body ILIKE ?", "%National insurance number%"
          ).count
        ).to eq 1
      end

      it "doesn't pass the task" do
        task = claim.tasks.teacher_auth_identity_confirmation.sole

        expect(task.passed).to eq nil
        expect(task.manual).to be false
      end
    end

    context "when name doesn't match" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::StudentLoans,
          first_name: "Seymour",
          surname: "Skinner",
          eligibility_attributes: {
            teacher_auth_first_name: "Walter",
            teacher_auth_last_name: "Skinner"
          },
          dqt_teacher_status: {
            qts: {
              holdsFrom: "2014-01-01"
            }
          }
        )
      end

      before { described_class.new(claim: claim).perform }

      it "adds a note to the claim" do
        expect(
          claim.notes.by_label("teacher_auth_identity_confirmation").where(
            "body ILIKE ?", "%Name%"
          ).count
        ).to eq 1
      end

      it "doesn't pass the task" do
        task = claim.tasks.teacher_auth_identity_confirmation.sole

        expect(task.passed).to eq nil
        expect(task.manual).to be false
      end
    end

    context "when date_of_birth doesn't match" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::StudentLoans,
          date_of_birth: Date.new(1980, 1, 1),
          eligibility_attributes: {
            teacher_auth_date_of_birth: Date.new(1970, 1, 1)
          },
          dqt_teacher_status: {
            qts: {
              holdsFrom: "2014-01-01"
            }
          }
        )
      end

      before { described_class.new(claim: claim).perform }

      it "adds a note to the claim" do
        expect(
          claim.notes.by_label("teacher_auth_identity_confirmation").where(
            "body ILIKE ?", "%Date of birth%"
          ).count
        ).to eq 1
      end

      it "doesn't pass the task" do
        task = claim.tasks.teacher_auth_identity_confirmation.sole

        expect(task.passed).to eq nil
        expect(task.manual).to be false
      end
    end

    context "when active alert" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::StudentLoans,
          dqt_teacher_status: {
            alerts: [
              {
                startDate: "2026-02-03",
                endDate: nil
              }
            ],
            qts: {
              holdsFrom: "2014-01-01"
            }
          }
        )
      end

      before { described_class.new(claim: claim).perform }

      it "adds a note to the claim" do
        note = claim.notes.by_label("teacher_auth_identity_confirmation").where(
          "body ILIKE ?", "%active alert%"
        ).sole

        expect(note).to be_important
      end

      it "doesn't pass the task" do
        task = claim.tasks.teacher_auth_identity_confirmation.sole

        expect(task.passed).to eq nil
        expect(task.manual).to be false
      end
    end

    context "when everything matches and there's not alert" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::StudentLoans,
          first_name: "Seymour",
          surname: "Skinner",
          date_of_birth: Date.new(1970, 1, 1),
          national_insurance_number: "AB123456C",
          eligibility_attributes: {
            teacher_auth_first_name: "Seymour",
            teacher_auth_last_name: "Skinner",
            teacher_auth_date_of_birth: Date.new(1970, 1, 1),
            teacher_auth_national_insurance_number: "AB123456C"
          },
          dqt_teacher_status: {
            qts: {
              holdsFrom: "2014-01-01"
            }
          }
        )
      end

      before { described_class.new(claim: claim).perform }

      it "doesn't create any notes" do
        expect(
          claim.notes.by_label("teacher_auth_identity_confirmation")
        ).to be_empty
      end

      it "passes the task" do
        task = claim.tasks.teacher_auth_identity_confirmation.sole

        expect(task.passed).to eq true
        expect(task.manual).to be false
      end
    end
  end
end
