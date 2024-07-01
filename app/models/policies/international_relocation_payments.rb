module Policies
  module InternationalRelocationPayments
    include BasePolicy
    extend self

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["passport_number"]].freeze
    OTHER_CLAIMABLE_POLICIES = []

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 100

    # NOTE RL: currently IRP only has a single reply to address, so notify
    # doesn't show the address id
    def notify_reply_to_id
      nil
    end
  end
end
