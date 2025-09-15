module Journeys
  module FurtherEducationPayments
    class ExistingProgressForm < Form
      attribute :start_new_claim, :boolean

      validates :start_new_claim,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(
            id: false,
            name: "Continue with the eligibility check that you have already started"
          ),
          Option.new(
            id: true,
            name: "Start a new eligibility check"
          )
        ]
      end

      def save
        return false if invalid?

        if start_new_claim == false
          migrator = JourneySessionMigrator.new(
            from: existing_journey_session_to_migrate_from,
            to: journey_session
          )
          migrator.call
        end

        journey_session
          .answers
          .assign_attributes(start_new_claim:)
        journey_session.save!

        true
      end

      def resume?
        start_new_claim == false
      end

      private

      def existing_journey_session_to_migrate_from
        one_login_account
          .resumable_journey_sessions(journey: Journeys::FurtherEducationPayments)
          .reject { |js| js.id == journey_session.id }
          .last
      end

      def one_login_account
        @one_login_account ||= OneLoginAccount.new(
          uid: journey_session.answers.onelogin_uid
        )
      end
    end
  end
end
