require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FeRepeatApplicantCheck do
  subject { described_class.new(claim:) }

  let(:academic_year) { AcademicYear.new(2025) }
  let(:last_note) { claim.reload.notes.order(created_at: :desc).limit(1).first }

  describe "#perform" do
    let(:claim) do
      create(
        :claim,
        :further_education,
        eligibility:,
        academic_year:
      )
    end

    context "when teaching start year mismatch is flagged" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          flagged_as_mismatch_on_teaching_start_year: true
        )
      end

      let!(:previous_ay_claim) do
        create(
          :claim,
          :further_education,
          :approved,
          academic_year: academic_year - 1,
          onelogin_uid: claim.onelogin_uid,
          eligibility: create(
            :further_education_payments_eligibility,
            further_education_teaching_start_year: "2020"
          )
        )
      end

      context "when it is a year 2 claim" do
        it "persists task with passed=nil and creates a year 2 specific note" do
          expect {
            subject.perform
          }.to change(Note, :count).by(1)
            .and not_change(Task, :count)

          expect(last_note.body).to eq("Year 1 claim exists for claimant with teaching start year 2020/2021 with claim reference: #{previous_ay_claim.reference}")
          expect(claim.reload.eligibility.repeat_applicant_check_passed).to be_nil
        end
      end

      context "when it is year 3 or later claim" do
        let(:academic_year) { AcademicYear.new(2026) }

        it "persists task with passed=nil and creates a generic mismatch note" do
          expect {
            subject.perform
          }.to change(Note, :count).by(1)
            .and not_change(Task, :count)

          expect(last_note.body).to eq("Teaching start year does not match approved claim start year from a previous academic year with claim reference: #{previous_ay_claim.reference}")
          expect(claim.reload.eligibility.repeat_applicant_check_passed).to be_nil
        end
      end

      context "when task already persisted" do
        before do
          Task.create!(
            name: "fe_repeat_applicant_check",
            claim:,
            passed: true
          )
        end

        it "does not create another task or note" do
          expect {
            subject.perform
          }.to not_change(Task, :count)
            .and not_change(Note, :count)

          expect(claim.reload.eligibility.repeat_applicant_check_passed).to be_nil
        end
      end
    end

    context "when teaching start year mismatch is not flagged" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          flagged_as_mismatch_on_teaching_start_year: false
        )
      end

      it "persists a task but does not create a note" do
        expect {
          subject.perform
        }.to change(Task, :count).by(1)
          .and not_change(Note, :count)

        expect(Task.last.passed?).to be true
        expect(claim.reload.eligibility.repeat_applicant_check_passed).to be true
      end
    end
  end
end
