require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::OverdueChaserEmailJob, type: :job, feature_flag: [:fe_provider_dashboard] do
  let(:provider) { create(:eligible_fe_provider) }

  let(:school) { create(:school, :further_education, ukprn: provider.ukprn) }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it "doesn't send emails for claims that are not overdue" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      created_at: 1.week.ago
    )

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).not_to have_received_email(
      "ad2d4486-4099-414b-a3c4-c0653510bc6e"
    )
  end

  it "doesn't send emails for claims that have been verified" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_completed_at: 1.day.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      created_at: 3.weeks.ago
    )

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).not_to have_received_email(
      "ad2d4486-4099-414b-a3c4-c0653510bc6e"
    )
  end

  it "doesn't send more than one email per week for overdue claims" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_chase_email_last_sent_at: 6.days.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      created_at: 3.weeks.ago
    )

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).not_to have_received_email(
      "ad2d4486-4099-414b-a3c4-c0653510bc6e"
    )
  end

  it "doesn't send emails for claims that have had more than 3 chasers sent" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      created_at: 5.weeks.ago
    )

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).not_to have_received_email(
      "ad2d4486-4099-414b-a3c4-c0653510bc6e"
    )
  end

  it "sends emails for overdue claims that meet the criteria" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_chase_email_last_sent_at: 8.days.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      created_at: 4.weeks.ago + 6.days
    )

    described_class.new.perform

    expect(provider.primary_key_contact_email_address).to have_received_email(
      "ad2d4486-4099-414b-a3c4-c0653510bc6e",
      link_to_provider_dashboard: "http://www.example.com/further-education-payments/providers/claims"
    )
  end
end
