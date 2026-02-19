require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2 do
  subject { described_class.new(claim) }

  describe "#perform" do
    let(:claim) do
      create(
        :claim,
        :further_education,
        eligibility:
      )
    end

    context "automatically failing the task" do
      context "when the provider has sellected no for teaching responsibilities" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_teaching_responsibilities: false
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["no_teaching_responsibilities"]})
        end
      end

      context "when the provider and claimant teaching start hours don't match" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            further_education_teaching_start_year: "2023",
            provider_verification_teaching_start_year: "2020"
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["teaching_start_year_mismatch"]})
        end
      end

      context "when the provider has selected the claimant doesn't teach the correct age range" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_half_teaching_hours: false
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["incorrect_age_range_taught"]})
        end
      end

      context "when the provider has selected that the claimant doesn't teach the courses they claim" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_half_timetabled_teaching_time: false
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["does_not_teach_claimed_courses"]})
        end
      end

      context "when the provider has selected yes for performance measures" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_performance_measures: true
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["performance_measures"]})
        end
      end

      context "when the provider has selected yes for disciplinary action" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_disciplinary_action: true
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["disciplinary_action"]})
        end
      end

      context "when the provider says the claimant does not plan to enroll on a qualification" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_teaching_qualification: "no_not_planned"
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["no_plans_for_teaching_qualification"]})
        end
      end

      context "when provider declares no for claimant continued employment" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_continued_employment: false
          )
        end

        it "persists task as failed" do
          expect {
            subject.perform
          }.to change(Task, :count).by(1)

          expect(Task.last.passed?).to be_falsey
          expect(Task.last.data).to eq({"failed_checks" => ["no_continued_employment"]})
        end

        context "when task already persisted" do
          before do
            Task.create!(
              name: described_class::TASK_NAME,
              claim:,
              passed: true
            )
          end

          it "not create another task" do
            expect {
              subject.perform
            }.to not_change(Task, :count)
          end
        end
      end

      context "when provider declares yes for claimant continued employment" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            provider_verification_continued_employment: true
          )
        end

        it "does not persist a task" do
          expect {
            subject.perform
          }.to not_change(Task, :count)
        end
      end

      context "when the claimant doesn't have a valid reason for not starting their qualification" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_verification_not_started_qualification_reasons: ["no_valid_reason"]
          )
        end

        it "creates a failed task" do
          subject.perform

          task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

          expect(task.failed?).to be true
          expect(task.manual?).to be false
          expect(task.data["failed_checks"]).to include(
            "no_valid_reason_for_not_starting_qualification"
          )
        end
      end

      context "when the claimant has a valid reason for not starting their qualification" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_verification_not_started_qualification_reasons: ["workload"],
            contract_type: "fixed_term",
            provider_verification_contract_type: "fixed_term"
          )
        end

        it "doesn't create a failed task" do
          expect { subject.perform }.not_to change { claim.tasks.where(passed: false).count }
        end
      end

      context "when the provider states the claimant teaches fewer than 2.5 hours" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_verification_teaching_hours_per_week: "fewer_than_2_and_a_half_hours_per_week"
          )
        end

        it "creates a failed task" do
          subject.perform

          task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

          expect(task.failed?).to be true
          expect(task.manual?).to be false
          expect(task.data["failed_checks"]).to include(
            "insufficient_teaching_hours_per_week"
          )
        end
      end

      context "when the provider states the claimant teaches 2.5 hours or more" do
        context "when the the claimant selects 12 or more hours" do
          let(:eligibility) do
            build(
              :further_education_payments_eligibility,
              :eligible,
              :provider_verification_completed,
              provider_verification_teaching_hours_per_week: "2_and_a_half_to_12_hours_per_week",
              teaching_hours_per_week: "more_than_12"
            )
          end

          it "creates a failed task" do
            subject.perform

            task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

            expect(task.failed?).to be true
            expect(task.manual?).to be false
            expect(task.data["failed_checks"]).to include(
              "mismatch_in_teaching_hours"
            )
          end
        end

        context "when the claimant select 20 hours or more" do
          let(:eligibility) do
            build(
              :further_education_payments_eligibility,
              :eligible,
              :provider_verification_completed,
              provider_verification_teaching_hours_per_week: "2_and_a_half_to_12_hours_per_week",
              teaching_hours_per_week: "more_than_20"
            )
          end

          it "creates a failed task" do
            subject.perform

            task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

            expect(task.failed?).to be true
            expect(task.manual?).to be false
            expect(task.data["failed_checks"]).to include(
              "mismatch_in_teaching_hours"
            )
          end
        end
      end

      context "when the claimant teaches between_2_5_and_12" do
        context "when the provider selects 12 or more hours" do
          let(:eligibility) do
            build(
              :further_education_payments_eligibility,
              :eligible,
              :provider_verification_completed,
              provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week",
              teaching_hours_per_week: "between_2_5_and_12"
            )
          end

          it "creates a failed task" do
            subject.perform

            task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

            expect(task.failed?).to be true
            expect(task.manual?).to be false
            expect(task.data["failed_checks"]).to include(
              "mismatch_in_teaching_hours"
            )
          end
        end

        context "when the provider selects 20 hours or more" do
          let(:eligibility) do
            build(
              :further_education_payments_eligibility,
              :eligible,
              :provider_verification_completed,
              provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
              teaching_hours_per_week: "between_2_5_and_12"
            )
          end

          it "creates a failed task" do
            subject.perform

            task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

            expect(task.failed?).to be true
            expect(task.manual?).to be false
            expect(task.data["failed_checks"]).to include(
              "mismatch_in_teaching_hours"
            )
          end
        end
      end

      context "when the provider states the claimant has not worked the full term" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_verification_taught_at_least_one_academic_term: false
          )
        end

        it "creates a failed task" do
          subject.perform

          task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

          expect(task.failed?).to be true
          expect(task.manual?).to be false
          expect(task.data["failed_checks"]).to include(
            "did_not_teach_full_academic_term"
          )
        end
      end

      context "when the provider states the claimant doens't have a direct contract of employment" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_verification_contract_type: "no_direct_contract"
          )
        end

        it "creates a failed task" do
          subject.perform

          task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

          expect(task.failed?).to be true
          expect(task.manual?).to be false
          expect(task.data["failed_checks"]).to include(
            "no_direct_contract_of_employment"
          )
        end
      end
    end

    context "automatically passing the task" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          provider_verification_teaching_responsibilities: true,
          further_education_teaching_start_year: "2023",
          provider_verification_teaching_start_year: "2023",
          provider_verification_half_teaching_hours: true,
          provider_verification_half_timetabled_teaching_time: true,
          provider_verification_performance_measures: false,
          provider_verification_disciplinary_action: false,
          provider_verification_contract_type: "permanent",
          contract_type: "permanent",
          provider_verification_teaching_qualification: "yes",
          provider_verification_continued_employment: true,
          provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
          teaching_hours_per_week: "more_than_20"
        )
      end

      it "passes the task" do
        subject.perform

        task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

        expect(task.passed?).to be true
        expect(task.manual?).to be false
        expect(task.data).to be nil
      end
    end
  end
end
