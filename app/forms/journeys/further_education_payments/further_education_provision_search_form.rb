module Journeys
  module FurtherEducationPayments
    class FurtherEducationProvisionSearchForm < Form
      MIN_LENGTH = 3

      attribute :provision_search, :string
      attribute :school_id, :string

      validates :provision_search,
        presence: { message: i18n_error_message(:blank) },
        length: { minimum: MIN_LENGTH, message: i18n_error_message(:min_length) },
        unless: Proc.new { |object| object.school_id.present? }

      def no_results?
        provision_search.present? && provision_search.size >=MIN_LENGTH && !has_results
      end

      def save
        return if invalid? || no_results?

        journey_session.answers.assign_attributes(
          provision_search:,
          school_id:
        )
        journey_session.save!

        true
      end

      private

      def has_results
        School.open.search(provision_search).count > 0
      end
    end
  end
end
