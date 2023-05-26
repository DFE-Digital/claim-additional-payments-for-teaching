module ClaimMailerHelper
  def rejected_reasons_personalisation(reasons)
    return {} unless reasons

    rejected_reasons_with_answers(reasons)
  end

  private

  def rejected_reasons_with_answers(reasons)
    reasons = replace_binary_values_with_yes_no(reasons)
    return reasons unless reasons_with_other?(reasons)

    reasons.reduce({}, &method(:ensure_other_reason_mutual_exclusivity))
  end

  def replace_binary_values_with_yes_no(reasons)
    reasons.each_with_object({}) do |(reason, answer), memo|
      memo[reason] = (answer == "1") ? "yes" : "no"
    end
  end

  def reasons_with_other?(reasons)
    reasons.any? { |key, answer| key == :reason_other && answer == "yes" }
  end

  def ensure_other_reason_mutual_exclusivity(memo, (key, _))
    memo.merge(key => (key == :reason_other) ? "yes" : "no")
  end
end
