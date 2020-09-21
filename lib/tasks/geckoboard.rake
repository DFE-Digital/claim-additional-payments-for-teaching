namespace :geckoboard do
  desc "Reset and recreate Geckoboard claims dataset"
  task reset: :environment do
    Claim::GeckoboardDataset.new.delete
    claims_to_update = []
    Policies.all.each do |policy|
      policy_configuration = PolicyConfiguration.for(policy)
      claims_to_update += Claim.by_policy(policy).by_academic_year(policy_configuration.current_academic_year).submitted
    end
    Claim::GeckoboardDataset.new(claims: claims_to_update).save
  end
end
