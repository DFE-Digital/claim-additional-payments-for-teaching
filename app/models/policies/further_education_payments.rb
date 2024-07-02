module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self
    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10
  end
end
