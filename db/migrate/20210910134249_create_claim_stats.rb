class CreateClaimStats < ActiveRecord::Migration[6.0]
  def change
    create_view :claim_stats, materialized: true
  end
end
