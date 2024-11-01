module AutomatedChecks
  module ClaimVerifiers
    class FraudRisk
      TASK_NAME = "fraud_risk".freeze

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return unless claim.attributes_flagged_by_risk_indicator.any?

        flagged_attributes = @claim
          .attributes_flagged_by_risk_indicator
          .map(&:humanize)
          .to_sentence
          .downcase

        plural_verbs = claim.attributes_flagged_by_risk_indicator.many? ? "are" : "is"

        body = "This claim has been flagged as the #{flagged_attributes} " \
          "#{plural_verbs} included on the fraud prevention list."

        claim.notes.create!(
          body: body,
          label: TASK_NAME
        )
      end

      private

      attr_reader :claim
    end
  end
end
