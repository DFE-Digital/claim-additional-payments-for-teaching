module Admin
  module PaymentHelper
    def list_references(payment)
      references = payment.claims.pluck(:reference)
      references.join("<br/>").html_safe
    end
  end
end
