module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        attribute :tid_sign_in, :boolean, pii: false
        attribute :details_correct, :boolean, pii: false
        attribute :check_your_answers_part_one_completed, :boolean, pii: false
        attribute :accept_payment, :boolean, pii: false
        attribute :payment_option, :string, pii: false
        attribute :check_your_answers_completed, :boolean, pii: false
      end
    end
  end
end
