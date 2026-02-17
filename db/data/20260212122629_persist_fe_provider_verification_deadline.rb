# Run me with `rails runner db/data/20260212122629_persist_fe_provider_verification_deadline.rb`

Policies::FurtherEducationPayments::Eligibility
  .where(provider_verification_deadline: nil)
  .includes(:claim)
  .find_each do |e|
    e.update!(provider_verification_deadline: (e.claim.created_at + 2.weeks).to_date)
  end
