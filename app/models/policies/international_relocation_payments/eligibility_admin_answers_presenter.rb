module Policies
  module InternationalRelocationPayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      def answers
        [].tap do |a|
          a << nationality
          a << passport_number
          a << current_school
          a << subject
          a << school_headteacher_name
          a << start_date
          a << visa_type
          a << date_of_entry
        end
      end

      private

      def nationality
        [
          admin_display_name("nationality"),
          eligibility.nationality
        ]
      end

      def passport_number
        [
          admin_display_name("passport_number"),
          eligibility.passport_number
        ]
      end

      def current_school
        [
          translate("admin.current_school"),
          display_school(eligibility.current_school)
        ]
      end

      def subject
        [
          admin_display_name("subject"),
          eligibility.subject.capitalize
        ]
      end

      def school_headteacher_name
        [
          admin_display_name("school_headteacher_name"),
          eligibility.school_headteacher_name
        ]
      end

      def start_date
        [
          admin_display_name("start_date"),
          eligibility.start_date.strftime("%-d %B %Y")
        ]
      end

      def visa_type
        [
          admin_display_name("visa_type"),
          eligibility.visa_type
        ]
      end

      def date_of_entry
        [
          admin_display_name("date_of_entry"),
          eligibility.date_of_entry.strftime("%-d %B %Y")
        ]
      end

      def admin_display_name(attr)
        translate(
          "international_relocation_payments.admin.eligibility_answers.#{attr}"
        )
      end
    end
  end
end
