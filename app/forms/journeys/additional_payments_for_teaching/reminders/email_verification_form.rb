module Journeys
  module AdditionalPaymentsForTeaching
    module Reminders
      class EmailVerificationForm < Form
        attribute :one_time_password
        attribute :sent_one_time_password_at

        # Required for shared partial in the view
        delegate :email_address, to: :claim

        validate :sent_one_time_password_must_be_valid
        validate :otp_must_be_valid, if: :sent_one_time_password_at?

        def self.model_name
          ActiveModel::Name.new(Form)
        end

        before_validation do
          self.one_time_password = one_time_password.gsub(/\D/, "")
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

          update!(email_verified: true)
        end

        private

        def sent_one_time_password_must_be_valid
          return if sent_one_time_password_at?

          errors.add(:one_time_password, i18n_errors_path(:"one_time_password.invalid"))
        end

        def otp_must_be_valid
          otp = OneTimePassword::Validator.new(
            one_time_password,
            sent_one_time_password_at
          )

          errors.add(:one_time_password, otp.warning) unless otp.valid?
        end

        def sent_one_time_password_at?
          sent_one_time_password_at&.to_datetime || false
        rescue Date::Error
          false
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
