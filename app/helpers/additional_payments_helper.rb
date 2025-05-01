module AdditionalPaymentsHelper
  include ActionView::Helpers::TextHelper

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end
end
