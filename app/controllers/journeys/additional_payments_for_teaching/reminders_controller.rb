module Journeys
  module AdditionalPaymentsForTeaching
    class RemindersController < BasePublicController
      include PartOfClaimJourney

      after_action :clear_sessions, only: :show
      helper_method :current_reminder

      include FormSubmittable
      include RemindersFormCallbacks

      private

      def load_form_if_exists
        @form ||= AdditionalPaymentsForTeaching::FORMS.dig(
          "reminders", params[:slug]
        )&.new(reminder: current_reminder, journey: Journeys::AdditionalPaymentsForTeaching, journey_session:, params:)
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
        return unless answers&.reminder_id

        Reminder.find(answers.reminder_id)
      end

      def submitted_claim
        @submitted_claim ||= Claim.includes(:eligibility).find_by(id: session[:submitted_claim_id])
      end

      def build_reminder_from_claim
        return unless model_for_reminder_attributes

        Reminder.new(
          full_name: model_for_reminder_attributes.full_name,
          email_address: model_for_reminder_attributes.email_address,
          itt_academic_year: next_academic_year,
          itt_subject: model_for_reminder_attributes.eligible_itt_subject,
          email_verified: model_for_reminder_attributes.email_verified? # allows the OTP to be skipped if already verified
        )
      end

      # Reminders can be set for in progress and submitted claims
      # We can tell if we're setting a reminder for a submitted claim as the
      # journey session will be nil given that we clear it on claim submission.
      def model_for_reminder_attributes
        @model_for_reminder_attributes ||= answers || submitted_claim
      end

      def send_to_start?
        model_for_reminder_attributes.nil?
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

        session.delete(journey_session_key)
      end
    end
  end
end
