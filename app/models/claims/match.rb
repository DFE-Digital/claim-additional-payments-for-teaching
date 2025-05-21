module Claims
  class Match < ApplicationRecord
    belongs_to :source_claim, class_name: "Claim"
    belongs_to :matching_claim, class_name: "Claim"
  end
end
