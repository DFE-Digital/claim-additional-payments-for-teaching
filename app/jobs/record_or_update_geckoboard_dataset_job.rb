class RecordOrUpdateGeckoboardDatasetJob < ApplicationJob
  def perform(claim_ids)
    claims = Claim.where(id: claim_ids)
    Claim::GeckoboardDataset.new(claims).save
  end
end
