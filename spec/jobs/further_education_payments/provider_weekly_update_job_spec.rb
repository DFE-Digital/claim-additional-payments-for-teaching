require "rails_helper"

RSpec.describe FurtherEducationPayments::ProviderWeeklyUpdateJob, type: :job do
  let(:provider1) do
    create(:dfe_signin_user,
      email: "provider1@college.edu",
      organisation_name: "Springfield FE College")
  end

  let(:provider2) do
    create(:dfe_signin_user,
      email: "provider2@college.edu",
      organisation_name: "Shelbyville FE College")
  end

  describe "#perform" do
    context "when there are unverified claims with assigned providers" do
      let!(:claim1) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      let!(:claim2) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      let!(:claim3) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider2))
      end

      it "sends weekly update emails to each provider with their claims" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        # Provider 1 should receive email with 2 claims
        expect("provider1@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
          "provider_name" => "Springfield FE College",
          "number_overall" => "2"
        )

        # Provider 2 should receive email with 1 claim
        expect("provider2@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
          "provider_name" => "Shelbyville FE College",
          "number_overall" => "1"
        )
      end

      it "updates email tracking for all claims" do
        freeze_time do
          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim1.reload
          claim2.reload
          claim3.reload

          expect(claim1.eligibility.provider_verification_email_last_sent_at).to be_within(1.second).of(DateTime.current)
          expect(claim1.eligibility.provider_verification_email_count).to eq(1)

          expect(claim2.eligibility.provider_verification_email_last_sent_at).to be_within(1.second).of(DateTime.current)
          expect(claim2.eligibility.provider_verification_email_count).to eq(1)

          expect(claim3.eligibility.provider_verification_email_last_sent_at).to be_within(1.second).of(DateTime.current)
          expect(claim3.eligibility.provider_verification_email_count).to eq(1)
        end
      end
    end

    context "when there are no unverified claims" do
      let!(:verified_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_assigned_to: provider1))
      end

      it "doesn't send any emails" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider1@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID]
        )
      end
    end

    context "when there are claims without assigned providers" do
      let!(:unassigned_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: nil))
      end

      it "doesn't send emails for unassigned claims" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when there are claims from other policies" do
      let!(:other_policy_claim) do
        create(:claim, :submitted,
          policy: Policies::StudentLoans)
      end

      it "doesn't send emails for non-FE claims" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when there are claims from previous academic years" do
      let!(:current_year_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.current,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      let!(:previous_year_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.new("2024/2025"),
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      it "only sends emails for current academic year claims" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        # Should receive email with only 1 claim (current year)
        expect("provider1@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
          "provider_name" => "Springfield FE College",
          "number_overall" => "1"
        )
      end
    end

    context "when there are claims older than the cutoff period" do
      let!(:recent_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.current,
          created_at: 1.month.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      let!(:old_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.current,
          created_at: 7.months.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      it "only sends emails for claims within the cutoff period" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        # Should receive email with only 1 claim (recent)
        expect("provider1@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
          "provider_name" => "Springfield FE College",
          "number_overall" => "1"
        )
      end
    end

    context "when the job is run multiple times in the same day" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider1))
      end

      it "doesn't send duplicate emails on the same day" do
        freeze_time do
          # Run the job once
          perform_enqueued_jobs do
            described_class.perform_now
          end

          # Clear deliveries
          ActionMailer::Base.deliveries.clear

          # Run the job again on the same day
          perform_enqueued_jobs do
            described_class.perform_now
          end

          # Should not send another email
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      it "increments email count only once per day" do
        freeze_time do
          # Run the job once
          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
          first_count = claim.eligibility.provider_verification_email_count

          # Run the job again on the same day
          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
          expect(claim.eligibility.provider_verification_email_count).to eq(first_count)
        end
      end
    end
  end
end
