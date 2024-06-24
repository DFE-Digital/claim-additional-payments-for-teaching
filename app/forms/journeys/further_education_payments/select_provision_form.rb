module Journeys
  module FurtherEducationPayments
    class SelectProvisionForm < Form
      attribute :school_id, :string # school GUID

      validates :school_id, presence: { message: i18n_error_message(:blank) }

      def radio_options
        results.map do |school|
          OpenStruct.new(
            id: school.id,
            name: school.name,
            address: school.address
          )
        end
      end

      def save
        return unless valid?

        journey_session.answers.assign_attributes(school_id:)
        journey_session.save!

        true
      end

      private

      def results
        @results ||= School.open.search(provision_search)
      end

      def provision_search
        journey_session.answers.provision_search
      end
    end
  end
end
