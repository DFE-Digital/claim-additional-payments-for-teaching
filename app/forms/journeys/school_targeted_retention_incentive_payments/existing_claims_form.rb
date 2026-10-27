module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class ExistingClaimsForm < Form
      def save
        false
      end

      def claims
        @claim ||= OneLoginAccount
          .new(uid: answers.teacher_auth_one_login_uid)
          .claims
          .where(policy: Policies::TargetedRetentionIncentivePayments)
          .where(academic_year: journey.configuration.current_academic_year)
      end
    end
  end
end
