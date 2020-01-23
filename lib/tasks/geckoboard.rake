namespace :geckoboard do
  desc "Reset and recreate Geckoboard claims dataset"
  task reset: :environment do
    Claim::GeckoboardDataset.new.delete
    Claim::GeckoboardDataset.new(claims: Claim.submitted).save
  end
end
