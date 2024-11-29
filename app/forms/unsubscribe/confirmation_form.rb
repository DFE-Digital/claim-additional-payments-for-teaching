module Unsubscribe
  class ConfirmationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :string

    def reminder
      @reminder ||= Reminder.find_by(id:)
    end

    def obfuscasted_email
      head, tail = reminder.email_address.split("@")

      mask = case head.size
      when 1, 2, 3
        "*" * head.size
      else
        [head[0], "*" * (head.length - 2), head[-1]].join
      end

      [mask, "@", tail].join
    end

    def journey_name
      I18n.t("journey_name", scope: reminder.journey::I18N_NAMESPACE).downcase
    end
  end
end
