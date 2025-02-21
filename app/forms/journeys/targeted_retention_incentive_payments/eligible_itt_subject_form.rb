module Journeys
  module TargetedRetentionIncentivePayments
    class EligibleIttSubjectForm < Form
      attribute :eligible_itt_subject, :string

      validates :eligible_itt_subject, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def radio_options
        subject_symbols.map do |subject_symbol|
          Option.new(
            id: subject_symbol.to_s,
            name: t("options.#{subject_symbol}")
          )
        end.push(
         Option.new(
           id: "none_of_the_above",
           name: t("options.none_of_the_above"),
         )
        )
      end

      private

      def subject_symbols
        Policies::TargetedRetentionIncentivePayments
          .current_and_future_subject_symbols(
            itt_year: answers.itt_academic_year,
            claim_year: journey.configuration.current_academic_year
          )
      end
    end
  end
end

