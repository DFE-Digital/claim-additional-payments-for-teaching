class SplitOlIdentityTasks < ActiveRecord::Migration[8.0]
  def change
    Task
      .joins(:claim)
      .where(name: "identity_confirmation")
      .merge(Claim.by_policies([Policies::FurtherEducationPayments]))
      .update_all(name: "one_login_identity")
  end
end
