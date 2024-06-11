module Journeys
  module AdditionalPaymentsForTeaching
    class EligibilityConfirmedForm < Form
      attribute :selected_claim_policy, :string

      validates :selected_claim_policy, presence: {message: ->(object, _) { object.i18n_errors_path(:blank) }}
      validates :selected_claim_policy, inclusion: {
        message: ->(object, _) { object.i18n_errors_path(:inclusion) },
        in: ->(object) { object.allowed_policy_names }
      }, if: -> { selected_claim_policy.present? }

      delegate :selected_policy, to: :claim, prefix: :current

      def save
        # This form doesn't directly persist anything; the controller currently calls `save`
        # on every form object, while for this form all we need is to call `valid?` instead.
        # TODO: If we change the data persistence layer for all forms, then this should be
        # revisited as well.
        valid?
      end

      def single_choice_only?
        eligibility_checker.single_choice_only?
      end

      def policies_eligible_now
        eligibility_checker.policies_eligible_now
      end

      def policies_eligible_now_and_sorted
        eligibility_checker.policies_eligible_now_and_sorted
      end

      def award_amount(policy)
        policy::PolicyEligibilityChecker.new(answers: shim.answers).calculate_award_amount
      end

      # TODO KL: This is still using the CurrentClaim for the selected policy
      def selected_policy?(policy)
        policy == current_selected_policy
      end

      def first_eligible_compact_policy_name
        policies_eligible_now_and_sorted.first.to_s.downcase
      end

      def allowed_policy_names
        policies_eligible_now_and_sorted.map(&:to_s)
      end

      def eligibility_checker
        @eligibility_checker ||= EligibilityChecker.new(journey_session: shim)
      end
    end
  end
end
