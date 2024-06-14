module Journeys
  module AdditionalPaymentsForTeaching
    module Reminders
      class PersonalDetailsForm < Form
        attribute :full_name
        attribute :email_address

        validates :full_name, presence: {message: i18n_error_message(:"full_name.blank")}
        validates :full_name, length: {maximum: 100, message: i18n_error_message(:"full_name.length")}

        validates :email_address, presence: {message: i18n_error_message(:"email_address.blank")}
        validates :email_address, format: {with: Rails.application.config.email_regexp, message: i18n_error_message(:"email_address.invalid")},
          length: {maximum: 256, message: i18n_error_message(:"email_address.length")}, if: -> { email_address.present? }

        def self.model_name
          ActiveModel::Name.new(Form)
        end

        # TODO RL: remove this and the initializer once reminders are writing
        # to the session
        attr_reader :claim

        def initialize(claim:, journey_session:, journey:, params:)
          @claim = claim
          super(journey_session:, journey:, params:)

          assign_attributes(attributes_with_current_value)
        end

        # TODO RL: remove this once reminders are writing to the session
        def update!(attrs)
          claim.update!(attrs)
        end

        def save
          return false unless valid?

          update!(attributes)
        end

        private

        def i18n_form_namespace
          "reminders.#{super}"
        end

        def load_current_value(attribute)
          # TODO: re-implement when the underlying claim and eligibility data sources
          # are moved to an alternative place e.g. a session hash

          # Some, but not all attributes are present directly on the claim record.
          return claim.public_send(attribute) if claim.has_attribute?(attribute)

          # At the moment, some attributes are unique to a policy eligibility record,
          # so we need to loop through all the claims in the wrapper and check each
          # eligibility individually; if the search fails, it should return `nil`.
          claim.claims.each do |c|
            return c.eligibility.public_send(attribute) if c.eligibility.has_attribute?(attribute)
          end
          nil
        end
      end
    end
  end
end
