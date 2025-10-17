require "rails_helper"

RSpec.describe FurtherEducationPayments::ProviderOverdueChaserJob, type: :job do
  let(:provider) do
    create(:dfe_signin_user,
      email: "provider@college.edu",
      organisation_name: "Springfield FE College")
  end

  describe "#perform" do
    context "when claim is overdue and eligible for first chaser" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 1))
      end

      it "sends the first chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID],
          "provider_name" => "Springfield FE College",
          "claimant_name" => claim.full_name,
          "claim_reference" => claim.reference
        )
      end

      it "updates chaser email tracking" do
        freeze_time do
          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
          expect(claim.eligibility.provider_verification_chase_email_last_sent_at).to be_within(1.second).of(DateTime.current)
          expect(claim.eligibility.provider_verification_email_count).to eq(2)
        end
      end
    end

    context "when claim is overdue and eligible for second chaser" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 4.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 15.days.ago,
            provider_verification_chase_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 2))
      end

      it "sends the second chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )

        claim.reload
        expect(claim.eligibility.provider_verification_email_count).to eq(3)
      end
    end

    context "when claim is overdue and eligible for third (final) chaser" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 5.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 22.days.ago,
            provider_verification_chase_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 3))
      end

      it "sends the third and final chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )

        claim.reload
        expect(claim.eligibility.provider_verification_email_count).to eq(4)
      end
    end

    context "when claim has already received 3 chasers (email_count = 4)" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 6.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_chase_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 4))
      end

      it "doesn't send any more chaser emails" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when claim is not yet overdue" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 1.week.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 1.day.ago,
            provider_verification_email_count: 1))
      end

      it "doesn't send a chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when weekly email was sent less than 1 week ago" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 5.days.ago,
            provider_verification_email_count: 1))
      end

      it "doesn't send a chaser email yet" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when last chaser was sent less than 1 week ago" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 4.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 15.days.ago,
            provider_verification_chase_email_last_sent_at: 5.days.ago,
            provider_verification_email_count: 2))
      end

      it "doesn't send another chaser email yet" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when claim has no weekly email sent yet (email_count = 0)" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_count: 0))
      end

      it "doesn't send a chaser email before weekly update" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when claim is verified" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            :provider_verification_completed,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 15.days.ago,
            provider_verification_email_count: 1))
      end

      it "doesn't send a chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect("provider@college.edu").not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID]
        )
      end
    end

    context "when claim has no assigned provider" do
      let!(:claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: nil,
            provider_verification_email_count: 1))
      end

      it "doesn't send a chaser email" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when there are claims from other policies" do
      let!(:other_policy_claim) do
        create(:claim, :submitted,
          policy: Policies::StudentLoans,
          created_at: 3.weeks.ago)
      end

      it "doesn't send chaser emails for non-FE claims" do
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
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 1))
      end

      let!(:previous_year_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.new("2024/2025"),
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 1))
      end

      it "only sends chaser emails for current academic year claims" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        # Should only receive one email (for current year claim)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect("provider@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID],
          "claim_reference" => current_year_claim.reference
        )
      end
    end

    context "when there are claims older than the cutoff period" do
      let!(:recent_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.current,
          created_at: 3.weeks.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 1))
      end

      let!(:old_claim) do
        create(:claim, :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.current,
          created_at: 7.months.ago,
          eligibility: create(:further_education_payments_eligibility,
            :eligible,
            provider_assigned_to: provider,
            provider_verification_email_last_sent_at: 8.days.ago,
            provider_verification_email_count: 1))
      end

      it "only sends chaser emails for claims within the cutoff period" do
        perform_enqueued_jobs do
          described_class.perform_now
        end

        # Should only receive one email (for recent claim)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect("provider@college.edu").to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID],
          "claim_reference" => recent_claim.reference
        )
      end
    end
  end
end
