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
        provider_verification_deadline: 1.day.ago,
        claim: create(
          :claim,
          :further_education,
          :submitted
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

  it "staggers weekly update emails due to Notify API 3000 per 60 seconds limit" do
    third_provider = create(:eligible_fe_provider, :with_school)

    [provider, other_provider, third_provider].each do |fe_provider|
      create(
        :further_education_payments_eligibility,
        :eligible,
        school: fe_provider.school,
        claim: create(
          :claim,
          :further_education,
          :submitted
        )
      )
    end

    deliver_later_calls = []
    mail_double = double("mail")
    mailer_scope_double = double("mailer scope", provider_weekly_update_email: mail_double)

    allow(mail_double).to receive(:deliver_later) do |wait: nil|
      deliver_later_calls << wait
    end

    allow(FurtherEducationPaymentsMailer).to receive(:with).and_return(mailer_scope_double)

    described_class.new.perform

    expect(deliver_later_calls).to eq([
      0.seconds,
      0.1.seconds,
      0.2.seconds
    ])
  end

  context "when there are versioned eligible FE providers" do
    let(:provider) { create(:eligible_fe_provider, :with_school) }

    let(:new_file_upload) do
      create(
        :file_upload,
        target_data_model: Policies::FurtherEducationPayments::EligibleFeProvider.to_s,
        academic_year: AcademicYear.current
      )
    end

    let!(:updated_provider) do
      create(
        :eligible_fe_provider,
        ukprn: provider.school.ukprn,
        file_upload: new_file_upload
      )
    end

    before do
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

    it "sends to new version of eligible FE provider" do
      described_class.new.perform

      expect(provider.primary_key_contact_email_address).not_to have_received_email(
        "7e019ad7-f2d8-43fe-8adc-a5c8609926ff"
      )

      expect(updated_provider.primary_key_contact_email_address).to have_received_email(
        "7e019ad7-f2d8-43fe-8adc-a5c8609926ff",
        provider_name: updated_provider.name,
        number_overdue: 0,
        number_in_progress: 0,
        number_not_started: 1,
        number_overall: 1,
        link_to_provider_dashboard: "http://www.example.com/further-education-payments/providers/claims"
      )
    end
  end
end
