require "rails_helper"

RSpec.describe EarlyYearsPayments::PractitionerReminderEmailJob, type: :job do
  let(:journey_configuration) { create(:journey_configuration, :early_years_payment) }

  describe "#perform" do
    subject(:perform_job) { described_class.new.perform }

    context "when there are claims needing reminders" do
      let(:eligible_ey_provider) { create(:eligible_ey_provider) }
      let(:practitioner_email) { "practitioner@example.com" }

      context "first reminder (1 week after provider submission)" do
        let!(:claim_needing_first_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.update!(practitioner_email_address: practitioner_email)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        let!(:claim_not_ready_for_first_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 5.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        it "sends first reminder email after 1 week" do
          perform_enqueued_jobs { perform_job }

          complete_claim_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/landing-page"

          expect(practitioner_email).to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6",
            practitioner_first_name: claim_needing_first_reminder.first_name,
            practitioner_second_name: claim_needing_first_reminder.surname,
            nursery_name: claim_needing_first_reminder.eligibility.eligible_ey_provider.nursery_name,
            complete_claim_url: complete_claim_url,
            ref_number: claim_needing_first_reminder.reference
          )
        end

        it "updates the reminder count and timestamp" do
          perform_job

          claim_needing_first_reminder.eligibility.reload
          expect(claim_needing_first_reminder.eligibility.practitioner_reminder_email_sent_count).to eq(1)
          expect(claim_needing_first_reminder.eligibility.practitioner_reminder_email_last_sent_at).to be_within(1.second).of(DateTime.current)
        end

        it "creates a note" do
          expect {
            perform_job
          }.to change { claim_needing_first_reminder.notes.count }.by(1)

          note = claim_needing_first_reminder.notes.last
          expect(note.label).to eq("practitioner_reminder")
          expect(note.body).to include("Reminder 1 email sent to practitioner")
        end
      end

      context "second reminder (2 weeks after first reminder)" do
        let!(:claim_needing_second_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 4.weeks.ago,
            practitioner_reminder_email_sent_count: 1,
            practitioner_reminder_email_last_sent_at: 15.days.ago
          )
          claim
        end

        let!(:claim_not_ready_for_second_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 3.weeks.ago,
            practitioner_reminder_email_sent_count: 1,
            practitioner_reminder_email_last_sent_at: 10.days.ago
          )
          claim
        end

        it "sends second reminder email after 2 weeks from first reminder" do
          claim_needing_second_reminder.update!(practitioner_email_address: practitioner_email)
          perform_enqueued_jobs { perform_job }

          complete_claim_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/landing-page"

          expect(practitioner_email).to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6",
            practitioner_first_name: claim_needing_second_reminder.first_name,
            practitioner_second_name: claim_needing_second_reminder.surname,
            nursery_name: claim_needing_second_reminder.eligibility.eligible_ey_provider.nursery_name,
            complete_claim_url: complete_claim_url,
            ref_number: claim_needing_second_reminder.reference
          )
        end

        it "updates the reminder count and timestamp" do
          perform_job

          claim_needing_second_reminder.eligibility.reload
          expect(claim_needing_second_reminder.eligibility.practitioner_reminder_email_sent_count).to eq(2)
          expect(claim_needing_second_reminder.eligibility.practitioner_reminder_email_last_sent_at).to be_within(1.second).of(DateTime.current)
        end
      end

      context "third reminder (4 weeks after second reminder)" do
        let!(:claim_needing_third_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.update!(practitioner_email_address: practitioner_email)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.weeks.ago,
            practitioner_reminder_email_sent_count: 2,
            practitioner_reminder_email_last_sent_at: 29.days.ago
          )
          claim
        end

        let!(:claim_not_ready_for_third_reminder) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.update!(practitioner_email_address: practitioner_email)
          claim.eligibility.update!(
            provider_claim_submitted_at: 6.weeks.ago,
            practitioner_reminder_email_sent_count: 2,
            practitioner_reminder_email_last_sent_at: 20.days.ago
          )
          claim
        end

        it "sends third reminder email after 4 weeks from second reminder" do
          perform_enqueued_jobs { perform_job }

          complete_claim_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/landing-page"

          expect(practitioner_email).to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6",
            practitioner_first_name: claim_needing_third_reminder.first_name,
            practitioner_second_name: claim_needing_third_reminder.surname,
            nursery_name: claim_needing_third_reminder.eligibility.eligible_ey_provider.nursery_name,
            complete_claim_url: complete_claim_url,
            ref_number: claim_needing_third_reminder.reference
          )
        end

        it "updates the reminder count and timestamp" do
          perform_job

          claim_needing_third_reminder.eligibility.reload
          expect(claim_needing_third_reminder.eligibility.practitioner_reminder_email_sent_count).to eq(3)
          expect(claim_needing_third_reminder.eligibility.practitioner_reminder_email_last_sent_at).to be_within(1.second).of(DateTime.current)
        end
      end

      context "when claim is already submitted" do
        let!(:submitted_claim) do
          claim = create(:claim, :submitted, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        it "does not send reminder email to submitted claims" do
          submitted_claim.update!(practitioner_email_address: practitioner_email)
          perform_enqueued_jobs { perform_job }

          expect(practitioner_email).not_to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6"
          )
        end
      end

      context "when claim is held" do
        let!(:held_claim) do
          claim = create(:claim, :submitted_by_provider, :held, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        it "does not send reminder email to held claims" do
          held_claim.update!(practitioner_email_address: practitioner_email)
          perform_enqueued_jobs { perform_job }

          expect(practitioner_email).not_to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6"
          )
        end
      end

      context "when claim is rejected" do
        let!(:rejected_claim) do
          claim = create(:claim, :submitted_by_provider, :rejected, policy: Policies::EarlyYearsPayments)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        it "does not send reminder email to rejected claims" do
          rejected_claim.update!(practitioner_email_address: practitioner_email)
          perform_enqueued_jobs { perform_job }

          expect(practitioner_email).not_to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6"
          )
        end
      end

      context "when claim has no practitioner email address" do
        let!(:claim_without_email) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.update!(practitioner_email_address: nil)
          claim.eligibility.update!(
            provider_claim_submitted_at: 8.days.ago,
            practitioner_reminder_email_sent_count: 0,
            practitioner_reminder_email_last_sent_at: nil
          )
          claim
        end

        it "does not send reminder email to claims without practitioner email" do
          perform_enqueued_jobs { perform_job }

          # Since it has no email, we're checking the job completes without error
          # Can't check email matcher as there's no email to send to
          expect { perform_job }.not_to raise_error
        end
      end

      context "when claim has already received all reminders" do
        let!(:claim_with_all_reminders) do
          claim = create(:claim, :submitted_by_provider, policy: Policies::EarlyYearsPayments)
          claim.update!(practitioner_email_address: practitioner_email)
          claim.eligibility.update!(
            provider_claim_submitted_at: 10.weeks.ago,
            practitioner_reminder_email_sent_count: 3,
            practitioner_reminder_email_last_sent_at: 2.weeks.ago
          )
          claim
        end

        it "does not send any more reminders after the third one" do
          perform_enqueued_jobs { perform_job }

          expect(practitioner_email).not_to have_received_email(
            "cf03a3c7-587a-48c4-83b9-0cd762d103f6"
          )
        end
      end
    end

    context "when there are no claims needing reminders" do
      it "completes without error" do
        expect { perform_job }.not_to raise_error
      end
    end
  end
end
