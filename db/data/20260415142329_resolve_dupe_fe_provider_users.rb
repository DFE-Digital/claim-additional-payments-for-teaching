# Run me with `rails runner db/data/20260415142329_resolve_dupe_fe_provider_users.rb`

eligibilites_verified_by_admins_count = Policies::FurtherEducationPayments::Eligibility
  .where(verified_by: DfeSignIn::User.admin)
  .count

puts "eligibilities verified by admins count is: #{eligibilites_verified_by_admins_count}"

external_ids = DfeSignIn::User.group(:dfe_sign_in_id).having("count(*) = 2").count.keys
users = DfeSignIn::User.where(dfe_sign_in_id: external_ids)
user_pairs = users.group_by { |u| u.dfe_sign_in_id }.values

user_pairs.each do |pair|
  admin_user = pair.find { |user| user.user_type == "admin" }
  provider_user = pair.find { |user| user.user_type == "provider" }

  raise "admin user not found" if admin_user.nil?
  raise "provider user not found" if provider_user.nil?

  eligibilities = Policies::FurtherEducationPayments::Eligibility
    .where(verified_by: admin_user)

  eligibilities.update(verified_by: provider_user)

  admin_user.mark_as_deleted!
end

eligibilites_verified_by_admins_count = Policies::FurtherEducationPayments::Eligibility
  .where(verified_by: DfeSignIn::User.admin)
  .count

puts "eligibilities verified by admins count is: #{eligibilites_verified_by_admins_count}"

remaining_not_deleted_count = DfeSignIn::User
  .admin
  .where(email: nil)
  .where.not(current_organisation_ukprn: nil)
  .where(deleted_at: nil)
  .count

puts "remaining not deleted count is: #{remaining_not_deleted_count}"
