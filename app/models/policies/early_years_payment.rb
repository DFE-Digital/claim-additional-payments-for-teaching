module Policies
  module EarlyYearsPayment
    include BasePolicy
    extend self

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

    # TODO: This is needed once the reply-to email address has been added to Gov Notify
    def notify_reply_to_id
      nil
    end
  end
end
