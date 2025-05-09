module Claims
  module ShowHelper
    def policy_name(policy)
      policy.short_name.downcase.singularize
    end

    def award_amount(amount)
      number_to_currency(amount, precision: 0)
    end
  end
end
