module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SignInForm < Form
        def save
          true
        end

        def completed?
          journey_session.answers.onelogin_uid && journey_session.answers.onelogin_idv_at.present?
        end
      end
    end
  end
end
