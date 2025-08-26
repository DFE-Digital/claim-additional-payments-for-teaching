module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class CheckYourAnswersForm < Form
          attr_reader :claim

          attribute :provider_contact_name

          validates :provider_contact_name, presence: {message: i18n_error_message(:valid)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(provider_contact_name:)
            journey_session.save!

            @claim = build_claim

            ApplicationRecord.transaction do
              set_attributes_for_claim_submission
              claim.save!
              mark_service_access_code_as_used!
            end

            claim.policy.mailer.submitted(claim).deliver_later

            ClaimMailer.early_years_payment_practitioner_email(claim).deliver_later

            send_provider_completed_emails

            session[:submitted_claim_id] = claim.id
            clear_claim_session

            true
          end

          def completed?
            session[:submitted_claim_id].present?
          end

          private

          def clear_claim_session
            key = "#{Journeys::EarlyYearsPayment::Provider::Authenticated}_journeys_session_id"
            session.delete(key)
          end

          def main_eligibility
            @main_eligibility ||= eligibilities.first
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

          def eligibilities
            @eligibilities ||= journey.policies.map do |policy|
              policy::Eligibility.new.tap do |eligibility|
                set_eligibility_attributes(eligibility)
                calculate_award_amount(eligibility)
              end
            end
          end

          def calculate_award_amount(eligibility)
            eligibility.award_amount = Policies::EarlyYearsPayments.award_amount
          end

          def set_eligibility_attributes(eligibility)
            answers.attributes.each do |name, value|
              if eligibility.respond_to?(:"#{name}=")
                eligibility.public_send(:"#{name}=", value)
              end
            end
          end

          def set_attributes_for_claim_submission
            claim.journey_session = journey_session
            claim.reference ||= generate_reference
            set_submitted_at_attributes
          end

          def set_submitted_at_attributes
            claim.eligibility.provider_claim_submitted_at = Time.zone.now
          end

          def mark_service_access_code_as_used!
            access_code = Journeys::ServiceAccessCode.find_by(
              code: answers.service_access_code,
              journey: journey_session.journey_class
            )
            access_code&.mark_as_used!
          end

          def send_provider_completed_emails
            claim.eligibility.eligible_ey_provider.email_addresses.each do |email_address|
              EarlyYearsPaymentsMailer.submitted_by_provider_and_send_to_provider(
                claim: claim,
                provider_email_address: email_address
              ).deliver_later
            end
          end

          def generate_reference
            loop {
              ref = Reference.new.to_s
              break ref unless Claim.exists?(reference: ref)
            }
          end
        end
      end
    end
  end
end
