class UnsetPersonalDataRemovedAtOnFeClaims < ActiveRecord::Migration[8.1]
  def change
    Claim
      .by_policy(Policies::FurtherEducationPayments)
      .update_all(personal_data_removed_at: nil)
  end
end
