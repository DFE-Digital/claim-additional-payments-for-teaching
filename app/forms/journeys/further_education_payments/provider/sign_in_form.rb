# Required to get page sequence to think this is a "normal" journey
module Journeys
  module FurtherEducationPayments
    module Provider
      class SignInForm < Form
        def completed?
          journey_session.answers.dfe_sign_in_uid.present?
        end
      end
    end
  end
end
