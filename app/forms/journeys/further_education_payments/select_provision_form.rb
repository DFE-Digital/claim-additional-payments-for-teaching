module Journeys
  module FurtherEducationPayments
    class SelectProvisionForm < Form
      attribute :school_id, :string # school GUID

      validates :school_id, presence: {message: i18n_error_message(:blank)}

      def radio_options
        results
      end

      def save
        return unless valid?

        journey_session.answers.assign_attributes(school_id:)
        journey_session.save!

        true
      end

      private

      def results
        @results ||= if journey_session.answers.school_id.present?
          School.open.where(id: school_id)
        else
          School.open.search(provision_search)
        end
      end

      def provision_search
        journey_session.answers.provision_search
      end
    end
  end
end
