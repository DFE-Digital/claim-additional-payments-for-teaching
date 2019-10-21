class Payment < ApplicationRecord
  belongs_to :claim
  belongs_to :payroll_run
end
