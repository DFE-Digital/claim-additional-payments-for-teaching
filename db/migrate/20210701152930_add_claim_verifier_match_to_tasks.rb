class AddClaimVerifierMatchToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :claim_verifier_match, :integer
  end
end
