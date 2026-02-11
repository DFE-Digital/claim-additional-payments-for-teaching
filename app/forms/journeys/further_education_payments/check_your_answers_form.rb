module Journeys
  module FurtherEducationPayments
    class CheckYourAnswersForm < Form
      attr_reader :claim

      attribute :claimant_declaration, :boolean

      validates :claimant_declaration,
        presence: {
          message: "Tick the box to confirm that the information " \
          "provided in this form is correct to the best of " \
          "your knowledge"
        }

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(claimant_declaration:)
        journey_session.save!

        if journey.requires_student_loan_details?
          journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
        end

        @claim = build_claim

        ApplicationRecord.transaction do
          set_attributes_for_claim_submission
          claim.save!
          mark_service_access_code_as_used!
          Event.create(claim:, name: "claim_submitted")
        end

        claim.policy.mailer.submitted(claim).deliver_later
        ClaimVerifierJob.perform_later(claim)

        if Policies::FurtherEducationPayments.duplicate_claim?(claim)
          claim.eligibility.update!(flagged_as_duplicate: true)
        end

        if Policies::FurtherEducationPayments.teaching_start_year_mismatch?(claim)
          claim.eligibility.update!(flagged_as_mismatch_on_teaching_start_year: true)
        end

        if Policies::FurtherEducationPayments.previous_claim_rejected_due_to_start_year_mismatch?(claim)
          claim.eligibility.update!(flagged_as_previously_start_year_matches_claim_false: true)
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
        key = "#{Journeys::FurtherEducationPayments.routing_name}_journeys_session_id"
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
        claim.decision_deadline = claim.decision_deadline_date
      end

      def set_eligibility_attributes(eligibility)
        answers.attributes.each do |name, value|
          if eligibility.respond_to?(:"#{name}=")
            eligibility.public_send(:"#{name}=", value)
          end
        end

        eligibility.provider_verification_deadline = Policies::FurtherEducationPayments.provider_verification_deadline(claim)
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
