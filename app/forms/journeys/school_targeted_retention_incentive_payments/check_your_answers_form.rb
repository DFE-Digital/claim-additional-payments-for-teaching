module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class CheckYourAnswersForm < Form
      attribute :claimant_declaration, :boolean

      validates :claimant_declaration,
        presence: {
          message: "Tick the box to confirm that the information " \
          "provided in this form is correct to the best of " \
          "your knowledge"
        }

      validate :validate_one_claim_for_window_for_ol_account

      def save
        return false if invalid?

        journey_session.answers.update!(claimant_declaration:)

        journey_session.answers.update!(
          date_of_birth: answers.teacher_auth_verified_date_of_birth
        )

        if journey.requires_student_loan_details?
          TargetedRetentionIncentivePayments::AnswersStudentLoansDetailsUpdater.call(journey_session)
        end

        claim = Claim.new.tap do |claim|
          answers.attributes.each do |name, value|
            if claim.respond_to?(:"#{name}=")
              claim.public_send(:"#{name}=", value)
            end
          end

          claim.award_amount = award_amount
          claim.policy = Policies::TargetedRetentionIncentivePayments
          claim.journey_session = journey_session
          claim.academic_year = journey.configuration.current_academic_year
          claim.eligibility = eligibility
          claim.submitted_at = Time.zone.now
          claim.decision_deadline = claim.decision_deadline_date
          claim.assign_new_reference
          claim.started_at = journey_session.created_at
          claim.dqt_teacher_status = answers.trs_data

          claim.first_name = answers.teacher_auth_verified_name.split(" ").first
          claim.surname = answers.teacher_auth_verified_name.split(" ").last
          claim.email_address = answers.teacher_auth_email
          claim.onelogin_uid = answers.teacher_auth_one_login_uid

          claim.onelogin_idv_first_name = answers.teacher_auth_verified_name.split(" ").first
          claim.onelogin_idv_last_name = answers.teacher_auth_verified_name.split(" ").last
          claim.onelogin_idv_full_name = answers.teacher_auth_verified_name
          claim.onelogin_idv_date_of_birth = answers.teacher_auth_verified_date_of_birth
        end

        ApplicationRecord.transaction do
          claim.save!
          Event.create(claim:, name: "claim_submitted")
          mark_service_access_code_as_used!
        end

        session[:submitted_claim_id] = claim.id

        true
      end

      def completed?
        session[:submitted_claim_id].present?
      end

      def redirect?
        @redirect
      end

      def redirect_to
        "/targeted-retention-incentive-payments/ineligible?ineligible_reason=claim_already_submitted_this_policy_year"
      end

      private

      def eligibility
        @eligibility ||= Policies::TargetedRetentionIncentivePayments::Eligibility.new.tap do |eligibility|
          answers.attributes.each do |name, value|
            if eligibility.respond_to?(:"#{name}=")
              eligibility.public_send(:"#{name}=", value)
            end

            eligibility.teacher_reference_number = answers.teacher_auth_teacher_reference_number
            eligibility.award_amount = award_amount
          end
        end
      end

      def mark_service_access_code_as_used!
        access_code = Journeys::ServiceAccessCode.find_by(
          code: answers.service_access_code,
          journey: journey_session.journey_class
        )
        access_code&.mark_as_used!
      end

      def validate_one_claim_for_window_for_ol_account
        claim = Claim.find_by(
          policy: Policies::TargetedRetentionIncentivePayments,
          onelogin_uid: answers.teacher_auth_one_login_uid,
          academic_year: journey.configuration.current_academic_year
        )

        if claim
          errors.add(:base, "You have already submitted a claim with the reference: #{claim.reference}")
          @redirect = true
        end
      end

      def award_amount
        Policies::TargetedRetentionIncentivePayments
          .award_amount(journey_session.answers.current_school)
      end
    end
  end
end
