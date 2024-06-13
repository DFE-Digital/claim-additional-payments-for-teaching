module Journeys
  module AdditionalPaymentsForTeaching
    class RemindersController < BasePublicController
      include PartOfClaimJourney

      after_action :clear_sessions, only: :show
      helper_method :current_reminder

      include FormSubmittable
      include RemindersFormCallbacks

      private

      # Wrapping `current_reminder` with an abstract method that is fed to the form object.
      def current_data_object
        current_reminder
      end

      def claim_from_session
        return unless session.key?(:claim_id) || session.key?(:submitted_claim_id)

        claims = Claim.includes(:eligibility).where(id: session[:claim_id] || session[:submitted_claim_id])
        claims.present? ? CurrentClaim.new(claims: claims) : nil
      end

      def slugs
        journey.slug_sequence::REMINDER_SLUGS
      end

      def next_slug
        slugs[current_slug_index + 1]
      end

      def current_slug
        slugs[current_slug_index]
      end

      def current_slug_index
        slugs.index(params[:slug]) || 0
      end

      def current_template
        "reminders/#{current_slug.underscore}"
      end

      def current_reminder
        @current_reminder ||=
          reminder_from_session ||
          build_reminder_from_claim ||
          default_reminder
      end

      def reminder_from_session
        return unless session.key?(:reminder_id)

        Reminder.find(session[:reminder_id])
      end

      def build_reminder_from_claim
        return unless current_claim

        Reminder.new(
          full_name: current_claim.full_name,
          email_address: current_claim.email_address,
          itt_academic_year: next_academic_year,
          itt_subject: journey_session.answers.eligible_itt_subject,
          email_verified: current_claim.email_verified? # allows the OTP to be skipped if already verified
        )
      end

      # Fallback reminder will set reminder date to the next academic year
      def default_reminder
        Reminder.new(itt_academic_year: next_academic_year)
      end

      def next_academic_year
        journey_configuration.current_academic_year + 1
      end

      def clear_sessions
        return unless current_slug == "set"

        session.delete(:claim_id)
        session.delete(:reminder_id)
      end
    end
  end
end
