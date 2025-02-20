module Journeys
  module TargetedRetentionIncentivePayments
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new
    end
  end
end
