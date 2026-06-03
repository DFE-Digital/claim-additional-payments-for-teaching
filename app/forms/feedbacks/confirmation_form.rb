module Feedbacks
  class ConfirmationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    def save
      false
    end
  end
end
