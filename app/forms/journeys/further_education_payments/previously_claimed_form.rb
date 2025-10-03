module Journeys
  module FurtherEducationPayments
    class PreviouslyClaimedForm < Form
      attribute :previously_claimed, :boolean

      validates :previously_claimed,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(
            id: true,
            name: t("options.true")
          ),
          Option.new(
            id: false,
            name: t("options.false")
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(previously_claimed:)
        journey_session.save!
      end

      def previous_claim_window_start
        "1 September #{AcademicYear.previous.start_year}"
      end

      def previous_claim_window_end
        "31 May #{AcademicYear.previous.end_year}"
      end
    end
  end
end
