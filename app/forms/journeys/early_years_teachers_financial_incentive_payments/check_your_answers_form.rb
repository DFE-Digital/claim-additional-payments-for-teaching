module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
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

        journey::AnswersStudentLoansDetailsUpdater.call(journey_session)

        @claim = build_claim

        ApplicationRecord.transaction do
          set_attributes_for_claim_submission
          claim.save!
          mark_service_access_code_as_used!
          Event.create(claim:, name: "claim_submitted")
        end

        claim.policy.mailer.submitted(claim).deliver_later
        ClaimVerifierJob.perform_later(claim)

        if Policies::EarlyYearsTeachersFinancialIncentivePayments.duplicate_claim?(claim)
          claim.eligibility.update!(flagged_as_duplicate: true)
        end

        journey_session.answers.assign_attributes(submitted_claim_id: claim.id)
        journey_session.save!

        session[:submitted_claim_id] = claim.id
        clear_claim_session

        true
      end

      private

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

          claim.email_address = answers.teacher_auth_email
          claim.first_name = first_name
          claim.surname = last_name
        end
      end

      def first_name
        answers.teacher_auth_verified_name.split(" ").first
      end

      def last_name
        answers.teacher_auth_verified_name.split(" ").last
      end

      def main_eligibility
        @main_eligibility ||= Policies::
          EarlyYearsTeachersFinancialIncentivePayments::
          Eligibility.new.tap do |eligibility|
          set_eligibility_attributes(eligibility)
        end
      end

      def set_eligibility_attributes(eligibility)
        answers.attributes.each do |name, value|
          if eligibility.respond_to?(:"#{name}=")
            eligibility.public_send(:"#{name}=", value)
          end
        end

        eligibility.award_amount = Policies::EarlyYearsTeachersFinancialIncentivePayments.award_amount
      end

      def set_attributes_for_claim_submission
        claim.journey_session = journey_session
        claim.reference ||= generate_reference
        claim.submitted_at = Time.zone.now
        claim.decision_deadline = claim.decision_deadline_date
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

      def clear_claim_session
        key = "#{Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name}_journeys_session_id"
        session.delete(key)
      end
    end
  end
end
