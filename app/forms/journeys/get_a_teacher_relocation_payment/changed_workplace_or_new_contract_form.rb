module Journeys
  module GetATeacherRelocationPayment
    class ChangedWorkplaceOrNewContractForm < Form
      attribute :changed_workplace_or_new_contract, :boolean

      validates :changed_workplace_or_new_contract,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def available_options
        [true, false]
      end

      def save
        return false unless valid?

        journey_session.answers.update!(changed_workplace_or_new_contract: changed_workplace_or_new_contract)
      end
    end
  end
end
