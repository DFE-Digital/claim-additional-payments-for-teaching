module Journeys
  module FurtherEducationPayments
    class HaveOneLoginAccountForm < Form
      attribute :have_one_login_account, :string

      validates :have_one_login_account,
        inclusion: {
          in: ["yes", "no", "i_dont_know"],
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(
            id: "yes",
            name: t("options.yes")
          ),
          Option.new(
            id: "no",
            name: t("options.no")
          ),
          Option.new(
            id: "i_dont_know",
            name: t("options.i_dont_know")
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(have_one_login_account:)
        journey_session.save!
      end
    end
  end
end
