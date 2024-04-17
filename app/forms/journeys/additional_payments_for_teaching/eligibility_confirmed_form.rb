module Journeys
  module AdditionalPaymentsForTeaching
    class EligibilityConfirmedForm < Form
      attribute :selected_claim_policy, :string

      validates :selected_claim_policy, presence: {message: ->(object, _) { object.i18n_errors_path(:blank) }}
      validates :selected_claim_policy, inclusion: {
        message: ->(object, _) { object.i18n_errors_path(:inclusion) },
        in: ->(object) { object.allowed_policy_names }
      }, if: -> { selected_claim_policy.present? }

      delegate :eligible_now, :eligible_now_and_sorted, to: :claim, prefix: :claims
      delegate :selected_policy, to: :claim, prefix: :current

      def save
        # This form doesn't directly persist anything; the controller currently calls `save`
        # on every form object, while for this form all we need is to call `valid?` instead.
        # TODO: If we change the data persistence layer for all forms, then this should be
        # revisited as well.
        valid?
      end

      def single_choice_only?
        claims_eligible_now.one?
      end

      def selected_policy?(policy)
        policy == current_selected_policy
      end

      def first_eligible_compact_policy_name
        claims_eligible_now_and_sorted.first.policy.to_s.downcase
      end

      def allowed_policy_names
        claims_eligible_now_and_sorted.map(&:policy).map(&:to_s)
      end
    end
  end
end
