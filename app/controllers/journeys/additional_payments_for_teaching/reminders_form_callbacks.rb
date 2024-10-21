module Journeys
  module AdditionalPaymentsForTeaching
    module RemindersFormCallbacks
      def personal_details_before_show
        try_mailer { set_a_reminder_immediately_if_possible }
      end

      def email_verification_before_show
        try_mailer { set_a_reminder_immediately_if_possible }
      end

      def email_verification_before_update
        inject_sent_one_time_password_at_into_the_form
      end

      def personal_details_after_form_save_success
        answers.reminder_id = current_reminder.to_param
        answers.email_verification_secret = ROTP::Base32.random
        journey_session.save!
        try_mailer { send_verification_email } || return
        redirect_to_next_slug
      end

      def email_verification_after_form_save_success
        try_mailer { send_reminder_set_email } || return
        redirect_to_next_slug
      end

      private

      def set_a_reminder_immediately_if_possible
        return if current_reminder.persisted?

        if current_reminder.email_verified? && current_reminder.save
          ReminderMailer.reminder_set(current_reminder).deliver_now

          redirect_to reminder_path(current_journey_routing_name, "set")
        end
      end

      def inject_sent_one_time_password_at_into_the_form
        params[:form]&.[]=(:sent_one_time_password_at, session[:sent_one_time_password_at])
      end

      def send_verification_email
        otp = OneTimePassword::Generator.new(secret: answers.email_verification_secret)
        ReminderMailer.email_verification(current_reminder, otp.code).deliver_now
        session[:sent_one_time_password_at] = Time.now
      end

      def send_reminder_set_email
        ReminderMailer.reminder_set(current_reminder).deliver_now
      end

      def try_mailer(&block)
        yield if block
        true
      rescue Notifications::Client::BadRequestError => e
        if notify_email_error?(e.message)
          render_template_for_current_slug
          false
        else
          raise
        end
      end

      def notify_email_error?(msg)
        case msg
        when "ValidationError: email_address is a required property"
          @form.errors.add(:email_address, :invalid, message: @form.i18n_errors_path(:"email_address.invalid"))
          true
        when "BadRequestError: Can’t send to this recipient using a team-only API key"
          @form.errors.add(:email_address, :invalid, message: @form.i18n_errors_path(:"email_address.unauthorised"))
          true
        else
          false
        end
      end
    end
  end
end
