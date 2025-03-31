module Journeys
  module FurtherEducationPayments
    class SelectProvisionForm < Form
      attribute :possible_school_id, :string # school GUID

      validates :possible_school_id, presence: {message: i18n_error_message(:blank)}

      def radio_options
        results
      end

      def save
        return unless valid?

        journey_session.answers.assign_attributes(
          school_id: possible_school_id
        )
        journey_session.save!
      end

      def completed?
        journey_session.answers.school_id.present?
      end

      private

      def results
        @results ||= if journey_session.answers.possible_school_id.present?
          School.fe_only.where(id: possible_school_id)
        else
          School.fe_only.search(provision_search)
        end
      end

      def provision_search
        journey_session.answers.provision_search
      end
    end
  end
end
