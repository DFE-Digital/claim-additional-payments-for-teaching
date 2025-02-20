# FIXME RL - write spec for this
# FIXME RL - implement the change school on the ineligibile page as a separte
# form
module Journeys
  module TargetedRetentionIncentivePayments
    class CorrectSchoolForm < Form
      attribute :confirm_recent_tps_school, :boolean

      validates :confirm_recent_tps_school, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) }
      }

      def initialize(...)
        super

        self.confirm_recent_tps_school = !answers.chose_recent_tps_school?
      end

      def radio_options
        [
          Option.new(
            id: true,
            name: answers.recent_tps_school.name,
            hint: answers.recent_tps_school.address
          ),
          Option.new(
            id: false,
            name: "Somewhere else",
          )
        ]
      end

      def save
        if confirm_recent_tps_school
          journey_session.answers.assign_attributes(
            current_school_id: answers.recent_tps_school.id,
            school_somewhere_else: false
          )
        else
          # Not sure amount the school_somewhere_else as on the AP journey
          # this seems to always be `false`? It's the school id that changes
          journey_session.answers.assign_attributes(
            current_school_id: "somewhere_else",
            school_somewhere_else: true
          )
        end

        journey_session.save!
      end
    end
  end
end
