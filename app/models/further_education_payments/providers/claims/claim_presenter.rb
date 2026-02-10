module FurtherEducationPayments
  module Providers
    module Claims
      class ClaimPresenter
        include Policies::FurtherEducationPayments::ProviderVerificationConstants

        attr_reader :claim

        delegate :full_name, :reference, :eligibility, to: :claim

        delegate :provider_verification_completed_at, to: :eligibility

        def initialize(claim)
          @claim = claim
        end

        def status
          case provider_verification_status
          when STATUS_NOT_STARTED
            "Not started"
          when STATUS_IN_PROGRESS
            "In progress"
          when STATUS_COMPLETED
            "Completed"
          when STATUS_REJECTED
            "Rejected"
          when STATUS_OVERDUE
            "Overdue"
          else
            "Unknown"
          end
        end

        def colour
          case provider_verification_status
          when STATUS_OVERDUE, STATUS_REJECTED
            "red"
          when STATUS_NOT_STARTED
            "yellow"
          when STATUS_IN_PROGRESS
            "blue"
          when STATUS_COMPLETED
            "green"
          else
            "grey"
          end
        end

        def dfe_status
          if Claim.not_awaiting_qa.include?(claim)
            :approved
          elsif Claim.rejected_not_awaiting_qa.include?(claim)
            :rejected
          else
            :pending
          end
        end

        def dfe_status_text
          I18n.t(
            dfe_status,
            scope: [
              :further_education_payments_provider,
              :presenters,
              :claim_presenter,
              :dfe_status
            ]
          )
        end

        def dfe_status_colour
          case dfe_status
          when :approved
            "green"
          when :rejected
            "red"
          when :pending
            "yellow"
          end
        end

        def processed_by
          eligibility.processed_by_label
        end

        private

        def provider_verification_status
          eligibility.provider_verification_status
        end
      end
    end
  end
end
