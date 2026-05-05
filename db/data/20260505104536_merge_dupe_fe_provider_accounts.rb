# Run me with `rails runner db/data/20260505104536_merge_dupe_fe_provider_accounts.rb`

external_ids = DfeSignIn::User.group(:dfe_sign_in_id).having("count(*) = 2").count.keys
users = DfeSignIn::User.where(dfe_sign_in_id: external_ids)
user_pairs = users.group_by { |u| u.dfe_sign_in_id }.values

user_pairs.each do |pair|
  admin_user = pair.find { |user| user.user_type == "admin" && user.deleted_at.present? }
  provider_user = pair.find { |user| user.user_type == "provider" }

  raise "admin user not found" if admin_user.nil?
  raise "provider user not found" if provider_user.nil?

  ApplicationRecord.transaction do
    if provider_user.role_codes.blank?
      provider_user.role_codes = admin_user.role_codes
    end

    if provider_user.current_organisation_ukprn.blank?
      provider_user.current_organisation_ukprn = admin_user.current_organisation_ukprn
    end

    events = Event.where(actor_id: admin_user.id)
    events.update(actor_id: provider_user.id)

    eligibilities = Policies::FurtherEducationPayments::Eligibility
      .where(verified_by: admin_user)

    eligibilities.update(provider_verification_verified_by_id: provider_user.id)

    eligibilities = Policies::FurtherEducationPayments::Eligibility
      .where(provider_assigned_to_id: admin_user.id)

    eligibilities.update(provider_assigned_to_id: provider_user.id)

    provider_user.save!
    admin_user.destroy!
  end
end
