module Journeys
  module AdditionalPaymentsForTeaching
    class EligibilityConfirmedForm < Form
      include ActionView::Helpers::NumberHelper

      attribute :selected_claim_policy, :string

      validates :selected_claim_policy, presence: {message: ->(object, _) { object.i18n_errors_path(:blank) }}
      validates :selected_claim_policy, inclusion: {
        message: ->(object, _) { object.i18n_errors_path(:inclusion) },
        in: ->(object) { object.allowed_policy_names }
      }, if: -> { selected_claim_policy.present? }

      delegate :selected_policy, to: :claim, prefix: :current

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(selected_policy: selected_claim_policy)
        journey_session.save!
      end

      def radio_options
        policies_eligible_now_and_sorted.map do |policy|
          Option.new(
            id: policy.to_s,
            name: "#{award_amount_with_currency(policy)} #{policy.short_name.downcase.singularize}",
            description: I18n.t("#{policy.locale_key}.purpose")
          )
        end
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
        policy::PolicyEligibilityChecker.new(answers: answers).calculate_award_amount
      end

      def award_amount_with_currency(policy)
        number_to_currency(award_amount(policy), precision: 0)
      end

      def selected_policy?(policy)
        policy.to_s == journey_session.answers.selected_policy
      end

      def first_eligible_compact_policy_name
        policies_eligible_now_and_sorted.first.to_s.downcase
      end

      def allowed_policy_names
        policies_eligible_now_and_sorted.map(&:to_s)
      end

      def eligibility_checker
        @eligibility_checker ||= EligibilityChecker.new(journey_session: journey_session)
      end
    end
  end
end
