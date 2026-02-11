require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::WeeklyUpdateEmailJob, type: :job, feature_flag: [:fe_provider_dashboard] do
  let(:provider) { create(:eligible_fe_provider, :with_school) }
  let(:other_provider) { create(:eligible_fe_provider, :with_school) }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it "sends a weekly email with unverified claim stats to the provider" do
    # Not started claims
    7.times do
      create(
        :further_education_payments_eligibility,
        :eligible,
        school: provider.school,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )
    end

    # In progress claims
    5.times do
      create(
        :further_education_payments_eligibility,
        :eligible,
        school: provider.school,
        provider_verification_started_at: 1.day.ago,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )

      # Create some claims for another provider to check we don't count them
      create(
        :further_education_payments_eligibility,
        :eligible,
        school: other_provider.school,
        provider_verification_started_at: 1.day.ago,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )
    end

    # Overdue claims
    3.times do
      create(
        :further_education_payments_eligibility,
        :eligible,
        school: provider.school,
        claim: create(
          :claim,
          :further_education,
          :submitted,
          created_at: 2.weeks.ago
        )
      )
    end

    # Verified claims (not included)
    5.times do
      create(
        :further_education_payments_eligibility,
        :eligible,
        :provider_verification_completed,
        school: provider.school,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )
    end

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).to have_received_email(
      "7e019ad7-f2d8-43fe-8adc-a5c8609926ff",
      provider_name: provider.name,
      number_overdue: 3,
      number_in_progress: 5,
      number_not_started: 10,
      number_overall: 15,
      link_to_provider_dashboard: "http://www.example.com/further-education-payments/providers/claims"
    )
  end

  it "doesn't send an email if there are no unverified claims" do
    5.times do
      create(
        :further_education_payments_eligibility,
        :eligible,
        :provider_verification_completed,
        school: provider.school,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )
    end

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).not_to have_received_email(
      "7e019ad7-f2d8-43fe-8adc-a5c8609926ff"
    )
  end
end
