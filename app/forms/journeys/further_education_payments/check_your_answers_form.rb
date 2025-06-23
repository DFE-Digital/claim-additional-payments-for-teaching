module Journeys
  module FurtherEducationPayments
    class CheckYourAnswersForm < Form
      attr_reader :claim

      def save
        return false if invalid?

        @claim = build_claim

        ApplicationRecord.transaction do
          set_attributes_for_claim_submission
          claim.save!
          mark_service_access_code_as_used!
        end

        claim.policy.mailer.submitted(claim).deliver_later
        ClaimVerifierJob.perform_later(claim)

        if Policies::FurtherEducationPayments.duplicate_claim?(claim)
          claim.eligibility.update!(flagged_as_duplicate: true)
        elsif FeatureFlag.enabled?(:alternative_idv) && !claim.identity_confirmed_with_onelogin?
          Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
            .send_further_education_payment_provider_verification_email
        elsif claim.one_login_idv_mismatch?
          # noop
          # do not send provider verification email
        else
          Policies::FurtherEducationPayments::ProviderVerificationEmails.new(claim)
            .send_further_education_payment_provider_verification_email
        end

        journey_session.answers.assign_attributes(submitted_claim_id: claim.id)
        journey_session.save!

        session[:submitted_claim_id] = claim.id
        clear_claim_session

        true
      end

      def completed?
        session[:submitted_claim_id].present?
      end

      private

      def clear_claim_session
        key = "#{Journeys::FurtherEducationPayments::ROUTING_NAME}_journeys_session_id"
        session.delete(key)
      end

      def build_claim
        Claim.new.tap do |claim|
          claim.eligibility ||= main_eligibility
          claim.policy ||= main_eligibility.policy
          claim.started_at = journey_session.created_at
          answers.attributes.each do |name, value|
            if claim.respond_to?(:"#{name}=")
              claim.public_send(:"#{name}=", value)
            end
          end
        end
      end

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      def eligibilities
        @eligibilities ||= journey.policies.map do |policy|
          policy::Eligibility.new.tap do |eligibility|
            set_eligibility_attributes(eligibility)
          end
        end
      end

      def set_attributes_for_claim_submission
        claim.journey_session = journey_session
        claim.reference ||= generate_reference
        claim.submitted_at = Time.zone.now
      end

      def set_eligibility_attributes(eligibility)
        answers.attributes.each do |name, value|
          if eligibility.respond_to?(:"#{name}=")
            eligibility.public_send(:"#{name}=", value)
          end
        end
      end

      def generate_reference
        loop {
          ref = Reference.new.to_s
          break ref unless Claim.exists?(reference: ref)
        }
      end

      def mark_service_access_code_as_used!
        access_code = Journeys::ServiceAccessCode.find_by(
          code: answers.service_access_code,
          journey: journey_session.journey_class
        )
        access_code&.mark_as_used!
      end
    end
  end
end
