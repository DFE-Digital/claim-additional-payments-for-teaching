class ClaimsPayment < ApplicationRecord
  belongs_to :claim
  belongs_to :payment
end
