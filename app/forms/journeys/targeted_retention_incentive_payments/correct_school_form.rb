module Journeys
  module TargetedRetentionIncentivePayments
    class CorrectSchoolForm < Form
      attribute :confirm_recent_tps_school, :boolean

      validates :confirm_recent_tps_school, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) }
      }

      def initialize(...)
        super

        # Set the default value for confirm_recent_tps_school
        unless permitted_params.has_key?(:confirm_recent_tps_school)
          self.confirm_recent_tps_school = !answers.chose_recent_tps_school?
        end
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
            name: "Somewhere else"
          )
        ]
      end

      def save
        return false unless valid?

        if confirm_recent_tps_school
          journey_session.answers.assign_attributes(
            current_school_id: answers.recent_tps_school.id,
            school_somewhere_else: false,
            award_amount: Policies::TargetedRetentionIncentivePayments.award_amount(
              answers.recent_tps_school
            )
          )
        else
          # Not sure abount the school_somewhere_else as on the AP journey
          # this seems to always be `false`? It's the school id that changes
          journey_session.answers.assign_attributes(
            current_school_id: "somewhere_else",
            school_somewhere_else: true,
            award_amount: nil
          )
        end

        journey_session.save!

        true
      end
    end
  end
end
