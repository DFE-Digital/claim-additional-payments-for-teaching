module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        attribute :accept_payment, :boolean, pii: false
        attribute :payment_option, :string, pii: false
        attribute :check_your_answers_completed, :boolean, pii: false
        attribute :payroll_gender_other, :string, pii: true
      end
    end
  end
end
