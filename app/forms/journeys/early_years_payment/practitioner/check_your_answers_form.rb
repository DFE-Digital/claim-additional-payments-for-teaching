module Journeys
  module EarlyYearsPayment
    module Practitioner
      class CheckYourAnswersForm < Form
        attr_reader :claim

        def save
          return false if invalid?

          if journey.requires_student_loan_details?
            journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
          end

          @claim = build_claim

          ApplicationRecord.transaction do
            set_attributes_for_claim_submission
            claim.save!
            mark_service_access_code_as_used!
          end

          claim.policy.mailer.submitted(claim).deliver_later
          ClaimVerifierJob.perform_later(claim)

          if claim.one_login_idv_failed?
            Provider::AlternativeIdv.send_alternative_idv_request!(claim)
          end

          session[:submitted_claim_id] = claim.id
          clear_claim_session

          true
        end

        def completed?
          session[:submitted_claim_id].present?
        end

        private

        def existing_or_new_claim
          Claim.find_by(reference: journey_session.answers.reference_number) || Claim.new
        end

        def build_claim
          existing_or_new_claim.tap do |claim|
            claim.eligibility ||= main_eligibility
            claim.policy ||= main_eligibility.policy
            claim.eligibility.practitioner_claim_started_at = journey_session.answers.practitioner_claim_started_at
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

        def set_submitted_at_attributes
          claim.submitted_at = Time.zone.now
        end

        def clear_claim_session
          key = "#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}_journeys_session_id"
          session.delete(key)
        end

        def set_attributes_for_claim_submission
          claim.journey_session = journey_session
          claim.reference ||= generate_reference
          set_submitted_at_attributes
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
end
