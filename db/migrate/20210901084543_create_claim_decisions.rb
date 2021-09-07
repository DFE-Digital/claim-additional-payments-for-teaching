class CreateClaimDecisions < ActiveRecord::Migration[6.0]
  def change
    create_view :claim_decisions
  end
end
