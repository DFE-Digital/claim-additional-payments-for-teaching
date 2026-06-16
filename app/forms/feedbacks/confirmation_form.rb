module Feedbacks
  class ConfirmationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :journey, :string

    def save
      false
    end

    def permitted_keys
      []
    end
  end
end
