class RemoveClaimIdFromPayments < ActiveRecord::Migration[6.0]
  def change
    remove_reference :payments, :claim
  end
end
