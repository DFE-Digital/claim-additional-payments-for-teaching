module Journeys
  module AdditionalPaymentsForTeaching
    module Reminders
      class EmailVerificationForm < ::EmailVerificationForm
        attribute :sent_one_time_password_at

        def self.model_name
          ActiveModel::Name.new(Form)
        end
      end
    end
  end
end
