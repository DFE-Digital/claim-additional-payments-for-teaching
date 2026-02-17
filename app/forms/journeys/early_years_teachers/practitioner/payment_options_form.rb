module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class PaymentOptionsForm < Form
        attribute :payment_option, :string

        validates :payment_option,
          inclusion: {
            in: %w[lump_sum monthly_instalments],
            message: i18n_error_message(:inclusion)
          }

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            payment_option: payment_option
          )
          journey_session.save!
        end

        def radio_options
          [
            OpenStruct.new(
              id: "lump_sum",
              name: t(:lump_sum_label),
              hint: t(:lump_sum_hint)
            ),
            OpenStruct.new(
              id: "monthly_instalments",
              name: t(:monthly_instalments_label),
              hint: t(:monthly_instalments_hint)
            )
          ]
        end
      end
    end
  end
end
