require "rails_helper"

RSpec.describe EarlyYearsPayments::ProviderSixMonthEmploymentReminderJob, type: :job do
  let(:eligible_ey_provider) do
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "seymor.skinner@springfield-elementary.edu",
      nursery_name: "Springfield Nursery"
    )
  end

  let(:eligibility) do
    create(
      :early_years_payments_eligibility,
      nursery_urn: eligible_ey_provider.urn,
      start_date: Date.new(2026, 1, 1),
      provider_claim_submitted_at: Date.new(2025, 6, 15)
    )
  end

  let(:claim) do
    create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsPayments,
      eligibility: eligibility,
      first_name: "Edna",
      surname: "Krabappel",
      provider_contact_name: "Seymour Skinner",
      academic_year: AcademicYear.new("2025/2026")
    )
  end

  describe "#perform" do
    before { claim }

    context "before 6 months have passed" do
      it "doesn't send an email" do
        travel_to(eligibility.start_date + 6.months - 1.day) do
          perform_enqueued_jobs do
            described_class.perform_now
          end
        end

        expect(
          "seymor.skinner@springfield-elementary.edu"
        ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
      end
    end

    context "after 6 months have passed" do
      context "when a rejected claim" do
        before do
          create(:decision, :rejected, claim: claim)
        end

        it "doesn't send an email" do
          travel_to(eligibility.start_date + 6.months) do
            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
        end
      end

      context "when an approved claim" do
        before do
          create(:task, name: "employment", passed: true, claim: claim)
          create(:decision, :approved, claim: claim)
        end

        it "doesn't send an email" do
          travel_to(eligibility.start_date + 6.months) do
            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
        end
      end

      context "when a year 1 claim" do
        before do
          claim.update!(academic_year: AcademicYear.new("2024/2025"))
        end

        it "doesn't send an email" do
          travel_to(eligibility.start_date + 6.months) do
            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
        end
      end

      context "when a reminder email has been sent" do
        it "doesn't send another email" do
          travel_to(eligibility.start_date + 6.months) do
            eligibility.update!(
              provider_six_month_employment_reminder_sent_at: Date.today - 1.day
            )

            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
        end
      end

      context "when a reminder email hasn't been sent" do
        it "sends a reminder email" do
          travel_to(eligibility.start_date + 6.months) do
            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).to have_received_email(
            "bc7faa96-8a19-4765-9d7a-6a6fd02aee9e",
            ref_number: claim.reference,
            provider_contact_name: "Seymour Skinner",
            practitioner_first_name: "Edna",
            practitioner_last_name: "Krabappel",
            provider_submission_date: "15 June 2025",
            nursery_name: "Springfield Nursery"
          )

          # Check we don't send the email again
          ActionMailer::Base.deliveries.clear

          travel_to(eligibility.start_date + 6.months + 1.day) do
            perform_enqueued_jobs do
              described_class.perform_now
            end
          end

          expect(
            "seymor.skinner@springfield-elementary.edu"
          ).not_to have_received_email("bc7faa96-8a19-4765-9d7a-6a6fd02aee9e")
        end
      end
    end
  end
end
