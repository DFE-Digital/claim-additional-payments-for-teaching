module Journeys
  module FurtherEducationPayments
    class FurtherEducationProvisionSearchForm < Form
      attribute :provision_search, :string

      validates :provision_search, presence: { message: i18n_error_message(:blank) }

      def save
        return unless valid?

        journey_session.answers.assign_attributes(provision_search:)
        journey_session.save!

        true
      end
    end
  end
end
