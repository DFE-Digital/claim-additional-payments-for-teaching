require "faker"

module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class HelloForm < Form
      def save
        journey_session.answers.update!(
          first_name: Faker::Name.first_name,
          surname: Faker::Name.last_name,
          date_of_birth: 20.years.ago,
          email_address: Faker::Internet.email
        )

        true
      end
    end
  end
end
