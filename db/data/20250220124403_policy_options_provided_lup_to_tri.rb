# Run me with `rails runner db/data/20250220124403_policy_options_provided_lup_to_tri.rb`

r = ActiveRecord::Base.connection.execute("SELECT id from (SELECT id, jsonb_path_query(policy_options_provided, '$.policy') AS options FROM \"claims\") as inner_table WHERE options = '\"LevellingUpPremiumPayments\"'")

ids = r.map { |e| e["id"] }

Claim.where(id: ids).find_each do |claim|
  policy_options_provided = claim.policy_options_provided
  index = policy_options_provided.index { |e| e["policy"] == "LevellingUpPremiumPayments" }
  policy_options_provided[index]["policy"] = "TargetedRetentionIncentivePayments"
  claim.update(policy_options_provided:)
  putc "."
end
