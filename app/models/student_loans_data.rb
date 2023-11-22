class StudentLoansData < ApplicationRecord
  scope :by_nino, ->(nino) { where(nino: nino) }
end
